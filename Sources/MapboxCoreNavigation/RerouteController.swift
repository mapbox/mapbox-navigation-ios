import Foundation
import MapboxDirections
@_implementationOnly import MapboxNavigationNative_Private

class RerouteController {

    // MARK: Configuration
    
    static let DefaultManeuverAvoidanceRadius: TimeInterval = 8.0

    var reroutesProactively: Bool = true

    var initialManeuverAvoidanceRadius: TimeInterval {
        get {
            config.avoidManeuverSeconds?.doubleValue ?? Self.DefaultManeuverAvoidanceRadius
        }
        set {
            config.avoidManeuverSeconds = NSNumber(value: newValue)
        }
    }

    private var config: NavigatorConfig

    // MARK: Reporting Data
    
    weak var delegate: ReroutingControllerDelegate?

    func userIsOnRoute() -> Bool {
        return !rerouteDetector.isReroute()
    }

    func forceReroute() {
        rerouteDetector.forceReroute()
    }

    // MARK: Internal State Management
    
    private let defaultRerouteController: RerouteControllerInterface
    private let rerouteDetector: RerouteDetectorInterface

    private weak var navigator: MapboxNavigationNative.Navigator?

    func resetToDefaultSettings() {
        reroutesProactively = true
        config.avoidManeuverSeconds = NSNumber(value: Self.DefaultManeuverAvoidanceRadius)
    }

    required init(_ navigator: MapboxNavigationNative.Navigator, config: NavigatorConfig) {
        self.navigator = navigator
        self.config = config
        self.defaultRerouteController = navigator.getRerouteController()
        self.rerouteDetector = navigator.getRerouteDetector()
        self.navigator?.addRerouteObserver(for: self)
    }

    deinit {
        self.navigator?.removeRerouteObserver(for: self)
    }
}

extension RerouteController: RerouteObserver {
    func onSwitchToAlternative(forRoute route: RouteInterface) {
        // TODO: fill with Native Alternative routes integration
    }

    func onRerouteDetected(forRouteRequest routeRequest: String) {
        // TODO: fill with Native RerouteController integration
        defaultRerouteController.cancel()
    }

    func onRerouteReceived(forRouteResponse routeResponse: String, routeRequest: String, origin: RouterOrigin) {
        // TODO: fill with Native RerouteController integration
    }

    func onRerouteCancelled() {
        // TODO: fill with Native RerouteController integration
    }

    func onRerouteFailed(forError error: RerouteError) {
        // TODO: fill with Native RerouteController integration
    }
}

extension RerouteController {
    static internal func decode(routeRequest: String, routeResponse: String) -> (routeOptions: RouteOptions, routeResponse: RouteResponse)? {
        guard let decodedRequest = decode(routeRequest: routeRequest),
              let decodedResponse = decode(routeResponse: routeResponse,
                                           routeOptions: decodedRequest.routeOptions,
                                           credentials: decodedRequest.credentials) else {
            return nil
        }

        return (decodedRequest.routeOptions, decodedResponse)
    }

    static internal func decode(routeRequest: String) -> (routeOptions: RouteOptions, credentials: Credentials)? {
        guard let requestURL = URL(string: routeRequest),
              let routeOptions = RouteOptions(url: requestURL) else {
                  return nil
        }

        return (routeOptions: routeOptions,
                credentials: Credentials(requestURL: requestURL))
    }

    static internal func decode(routeResponse: String,
                                routeOptions: RouteOptions,
                                credentials: Credentials) -> RouteResponse? {
        guard let data = routeResponse.data(using: .utf8) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.userInfo[.options] = routeOptions
        decoder.userInfo[.credentials] = credentials

        return try? decoder.decode(RouteResponse.self,
                                   from: data)
    }
}
