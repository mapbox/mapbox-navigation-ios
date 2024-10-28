import Foundation
import MapboxCommon
import MapboxDirections
import MapboxNavigationNative_Private

/// Adapter for `MapboxNavigationNative.RerouteControllerInterface` usage inside `Navigator`.
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

    func userIsOnRoute() -> Bool {
        return !(rerouteDetector?.isReroute() ?? false)
    }

    // MARK: Internal State Management

    private let defaultRerouteController: DefaultRerouteControllerInterface
    private let rerouteDetector: RerouteDetectorInterface?

    private weak var navigator: NavigationNativeNavigator?

    @MainActor
    required init(configuration: Configuration) {
        self.rerouteConfig = configuration.rerouteConfig
        self.navigator = configuration.navigator
        self.config = configuration.configHandle
        self.defaultInitialManeuverAvoidanceRadius = configuration.initialManeuverAvoidanceRadius
        self.defaultRerouteController = DefaultRerouteControllerInterface(
            nativeInterface: configuration.navigator.native.getRerouteController()
        ) {
            guard let url = URL(string: $0),
                  let options = RouteOptions(url: url)
            else {
                return $0
            }

            return Directions
                .url(
                    forCalculating: configuration.rerouteConfig.optionsCustomization?(options) ?? options,
                    credentials: .init(configuration.credentials)
                )
                .absoluteString
        }
        navigator?.native.setRerouteControllerForController(defaultRerouteController)
        self.rerouteDetector = configuration.navigator.native.getRerouteDetector()
        navigator?.native.addRerouteObserver(for: self)

        defer {
            self.initialManeuverAvoidanceRadius = configuration.initialManeuverAvoidanceRadius
        }
    }

    deinit {
        self.navigator?.removeRerouteObserver(for: self)
    }
}

extension RerouteController: RerouteObserver {
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

        RouteParser.parseDirectionsResponse(
            forResponseDataRef: routeResponse,
            request: routeRequest,
            routeOrigin: origin
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
                delegate?.rerouteControllerDidRecieveReroute(self, routesData: routesData)
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
