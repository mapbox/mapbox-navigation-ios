import Foundation
import MapboxCommon
import MapboxDirections
import MapboxNavigationNative_Private

/// Adapter for `MapboxNavigationNative_Private.RerouteControllerInterface` usage inside `Navigator`.
///
/// This class handles correct setup for `RerouteControllerInterface`, monitoring native reroute events and configuring
/// the process.
class RerouteController {
    // MARK: Configuration

    struct Configuration {
        let credentials: ApiConfiguration
        let navigator: NavigationNativeNavigator
        let configHandle: ConfigHandle
        let rerouteConfig: RerouteConfig
        let initialManeuverAvoidanceRadius: TimeInterval
    }

    var initialManeuverAvoidanceRadius: TimeInterval {
        get {
            config.mutableSettings().avoidManeuverSeconds()?.doubleValue ?? defaultInitialManeuverAvoidanceRadius
        }
        set {
            config.mutableSettings().setAvoidManeuverSecondsForSeconds(NSNumber(value: newValue))
        }
    }

    private var config: ConfigHandle
    private let rerouteConfig: RerouteConfig
    private let defaultInitialManeuverAvoidanceRadius: TimeInterval
    var abortReroutePipeline: Bool = false

    // MARK: Reporting Data

    weak var delegate: ReroutingControllerDelegate?

    // MARK: Internal State Management

    private var defaultRerouteController: DefaultRerouteControllerInterface?

    private weak var navigator: NavigationNativeNavigator?

    // Registered as the native reroute observer in place of `self`. See `RerouteObserverProxy`.
    private let observer = RerouteObserverProxy()

    @MainActor
    required init(configuration: Configuration) {
        self.rerouteConfig = configuration.rerouteConfig
        self.navigator = configuration.navigator
        self.config = configuration.configHandle
        self.defaultInitialManeuverAvoidanceRadius = configuration.initialManeuverAvoidanceRadius

        observer.controller = self

        let defaultRerouteController = makeDefaultRerouteController(configuration: configuration)
        self.defaultRerouteController = defaultRerouteController
        navigator?.native.setRerouteControllerForController(defaultRerouteController)
        navigator?.native.addRerouteObserver(for: observer)

        defer {
            self.initialManeuverAvoidanceRadius = configuration.initialManeuverAvoidanceRadius
        }
    }

    deinit {
        // Removal is asynchronous. Passing the proxy rather than `self` keeps the removal task from
        // retaining the controller while it is being deallocated.
        navigator?.removeRerouteObserver(for: observer)
    }
}

// Forwards native reroute callbacks to its `RerouteController`, which it holds weakly.
//
// Native does not retain observers, so the observer must be removed on teardown. Registering this proxy
// instead of the controller lets the controller's `deinit` trigger removal without the asynchronous removal
// retaining the controller mid-deallocation.
private final class RerouteObserverProxy: RerouteObserver {
    weak var controller: RerouteController?

    func onSwitchToAlternative(forRoute route: any RouteInterface, legIndex: UInt32) {
        controller?.onSwitchToAlternative(forRoute: route, legIndex: legIndex)
    }

    func onRerouteDetected(forRouteRequest routeRequest: String) -> Bool {
        controller?.onRerouteDetected(forRouteRequest: routeRequest) ?? false
    }

    func onRerouteReceived(forRouteResponse routeResponse: DataRef, routeRequest: String, origin: RouterOrigin) {
        controller?.onRerouteReceived(forRouteResponse: routeResponse, routeRequest: routeRequest, origin: origin)
    }

    func onRerouteCancelled() {
        controller?.onRerouteCancelled()
    }

    func onRerouteFailed(forError error: RerouteError) {
        controller?.onRerouteFailed(forError: error)
    }
}

extension RerouteController {
    @MainActor
    private func makeDefaultRerouteController(
        configuration: Configuration
    ) -> DefaultRerouteControllerInterface {
        let nativeRerouteController = configuration.navigator.native.getRerouteController()

        if let urlOptionsCustomization = configuration.rerouteConfig.urlOptionsCustomization {
            return DefaultRerouteControllerInterface(
                nativeInterface: nativeRerouteController,
                routeOptionsAdapter: DefaultRouteOptionsAdapter { urlOptionsCustomization($0) ?? $0 }
            )
        } else if let optionsCustomization = configuration.rerouteConfig.deprecatedOptionsCustomization {
            return DefaultRerouteControllerInterface(
                nativeInterface: nativeRerouteController,
                requestConfig: { [weak self] in
                    guard let self else { return $0 }

                    guard let options = delegate?.rerouteController(self, willModify: $0),
                          let customizedOptions = optionsCustomization(options)
                    else {
                        return $0
                    }

                    return Directions.url(
                        forCalculating: customizedOptions,
                        credentials: .init(configuration.credentials)
                    ).absoluteString
                }
            )
        } else {
            return DefaultRerouteControllerInterface(
                nativeInterface: nativeRerouteController,
                routeOptionsAdapter: nil
            )
        }
    }
}

// Reroute event handlers, invoked via `RerouteObserverProxy`. `RerouteController` deliberately does not
// conform to `RerouteObserver`: only the proxy is registered with native, which keeps the controller from
// being registered directly (its `deinit` cannot safely remove itself as an observer).
extension RerouteController {
    func onSwitchToAlternative(forRoute route: any RouteInterface, legIndex: UInt32) {
        delegate?.rerouteControllerWantsSwitchToAlternative(self, route: route, legIndex: Int(legIndex))
    }

    func onRerouteDetected(forRouteRequest routeRequest: String) -> Bool {
        guard rerouteConfig.detectsReroute else { return false }
        delegate?.rerouteControllerDidDetectReroute(self)
        return !abortReroutePipeline
    }

    func onRerouteReceived(forRouteResponse routeResponse: DataRef, routeRequest: String, origin: RouterOrigin) {
        guard rerouteConfig.detectsReroute else {
            Log.warning(
                "Reroute attempt fetched a route during 'rerouteConfig.detectsReroute' is disabled.",
                category: .navigation
            )
            return
        }

        let reason = RerouteReason(routeRequest: routeRequest)
        let routeParserClient = Environment.shared.routeParserClient
        routeParserClient.parseDirectionsResponseForResponseDataRefWithCallback(
            routeResponse,
            routeRequest,
            origin
        ) { [weak self] result in
            guard let self else { return }

            if result.isValue(),
               var routes = result.value as? [RouteInterface],
               !routes.isEmpty
            {
                let routesData = RouteParser.createRoutesData(
                    forPrimaryRoute: routes.remove(at: 0),
                    alternativeRoutes: routes
                )
                delegate?.rerouteControllerDidReceiveReroute(self, routesData: routesData, reason: reason)
            } else {
                delegate?.rerouteControllerDidFailToReroute(self, with: DirectionsError.invalidResponse(nil))
            }
        }
    }

    func onRerouteCancelled() {
        guard rerouteConfig.detectsReroute else { return }
        delegate?.rerouteControllerDidCancelReroute(self)
    }

    func onRerouteFailed(forError error: RerouteError) {
        guard rerouteConfig.detectsReroute else {
            Log.warning(
                "Reroute attempt failed with an error during 'rerouteConfig.detectsReroute' is disabled. Error: \(error.message)",
                category: .navigation
            )
            return
        }
        delegate?.rerouteControllerDidFailToReroute(
            self,
            with: DirectionsError.unknown(
                response: nil,
                underlying: ReroutingError(error),
                code: nil,
                message: error.message
            )
        )
    }
}
