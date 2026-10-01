import Foundation
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

    private var routeOptionsAdapter: RouteOptionsAdapter?

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

        configureNativeRerouteController(configuration: configuration)
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

    func onRerouteReceived(forRoutes routes: [any RouteInterface], origin: RouterOrigin) {
        controller?.onRerouteReceived(forRoutes: routes, origin: origin)
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
    private func configureNativeRerouteController(configuration: Configuration) {
        guard let nativeRerouteController = configuration.navigator.native.getRerouteController() else {
            return
        }
        guard let adapter = makeRouteOptionsAdapter(configuration: configuration) else {
            return
        }
        routeOptionsAdapter = adapter
        nativeRerouteController.setOptionsAdapterForRouteRequest(adapter)
    }

    @MainActor
    private func makeRouteOptionsAdapter(configuration: Configuration) -> RouteOptionsAdapter? {
        if let urlOptionsCustomization = configuration.rerouteConfig.urlOptionsCustomization {
            return DefaultRouteOptionsAdapter { urlOptionsCustomization($0) ?? $0 }
        }
        if let optionsCustomization = configuration.rerouteConfig.deprecatedOptionsCustomization {
            return DefaultRouteOptionsAdapter { [weak self] url in
                guard let self else { return url }
                guard let options = delegate?.rerouteController(self, willModify: url),
                      let customizedOptions = optionsCustomization(options)
                else {
                    return url
                }
                return Directions.url(
                    forCalculating: customizedOptions,
                    credentials: .init(configuration.credentials)
                ).absoluteString
            }
        }
        return nil
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
        guard rerouteConfig.detectsReroute, !abortReroutePipeline else { return false }
        delegate?.rerouteControllerDidDetectReroute(self)
        return true
    }

    func onRerouteReceived(forRoutes routes: [any RouteInterface], origin _: RouterOrigin) {
        guard rerouteConfig.detectsReroute else {
            Log.warning(
                "Reroute attempt fetched a route during 'rerouteConfig.detectsReroute' is disabled.",
                category: .navigation
            )
            return
        }

        // Navigation Native already parsed the directions response. Build route data from those
        // routes. The primary route's request URI still carries the reroute reason.
        guard let primaryRoute = routes.first else {
            delegate?.rerouteControllerDidFailToReroute(self, with: DirectionsError.invalidResponse(nil))
            return
        }
        let alternatives = Array(routes.dropFirst())

        let reason = RerouteReason(routeRequest: primaryRoute.getRequestUri())
        let routesData = Environment.shared.routeParserClient.createRoutesData(primaryRoute, alternatives)
        delegate?.rerouteControllerDidReceiveReroute(self, routesData: routesData, reason: reason)
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
