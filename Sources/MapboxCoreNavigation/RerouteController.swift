import Foundation
import MapboxDirections
@_implementationOnly import MapboxNavigationNative_Private

/**
 Adapter for `MapboxNavigationNative.RerouteControllerInterface` usage inside `Navigator`.
 
 This class handles correct setup for custom or default `RerouteControllerInterface`, monitoring native reroute events and configuring the process.
 */
class RerouteController {

    // MARK: Configuration
    
    static let DefaultManeuverAvoidanceRadius: TimeInterval = 8.0

    var reroutesProactively: Bool = true {
        didSet {
            if !reroutesProactively {
                reroutingRequest?.cancel()
            }
        }
    }

    var initialManeuverAvoidanceRadius: TimeInterval {
        get {
            config.avoidManeuverSeconds()?.doubleValue ?? Self.DefaultManeuverAvoidanceRadius
        }
        set {
            config.setAvoidManeuverSecondsForSeconds(NSNumber(value: newValue))
        }
    }

    var customRoutingProvider: RoutingProvider? = nil {
        didSet {
            self.navigator?.setRerouteControllerForController(
                customRoutingProvider != nil ? self : defaultRerouteController
            )
        }
    }
    
    private var config: ConfigHandle

    // MARK: Reporting Data
    
    weak var delegate: ReroutingControllerDelegate? {
        didSet {
            guard delegate != nil else {
                defaultRerouteController.requestConfig = nil
                return
            }

            defaultRerouteController.requestConfig = { [weak delegate] in
                guard let delegate = delegate,
                      let url = URL(string: $0),
                      let options = RouteOptions(url: url) else {
                    return $0
                }
                return NavigationSettings.shared.directions.url(forCalculating: delegate.rerouteControllerWillModify(options: options)).absoluteString
            }
        }
    }

    func userIsOnRoute() -> Bool {
        return !rerouteDetector.isReroute()
    }

    func forceReroute() {
        rerouteDetector.forceReroute()
    }

    // MARK: Internal State Management
    
    private let defaultRerouteController: DefaultRerouteControllerInterface
    private let rerouteDetector: RerouteDetectorInterface
    
    private var reroutingRequest: NavigationProviderRequest?
    private var latestRouteResponse: (response: RouteResponse, options: RouteOptions)?
    private var isCancelled = false
    
    private weak var navigator: MapboxNavigationNative.Navigator?

    func resetToDefaultSettings() {
        reroutesProactively = true
        isCancelled = false
        config.setAvoidManeuverSecondsForSeconds(NSNumber(value: Self.DefaultManeuverAvoidanceRadius))
        if customRoutingProvider != nil {
            customRoutingProvider = nil
        }
    }

    required init(_ navigator: MapboxNavigationNative.Navigator, config: ConfigHandle) {
        self.navigator = navigator
        self.config = config
        self.defaultRerouteController = DefaultRerouteControllerInterface(nativeInterface: navigator.getRerouteController())
        self.navigator?.setRerouteControllerForController(defaultRerouteController)
        self.rerouteDetector = navigator.getRerouteDetector()
        self.navigator?.addRerouteObserver(for: self)
    }

    deinit {
        self.navigator?.removeRerouteObserver(for: self)
        self.navigator?.setRerouteControllerForController(defaultRerouteController.nativeInterface)
    }
}

extension RerouteController: RerouteObserver {
    func onSwitchToAlternative(forRoute route: RouteInterface) {
        guard let decoded = Self.decode(routeRequest: route.getRequestUri(),
                                        routeResponse: route.getResponseJson()) else {
            return
        }
        
        delegate?.rerouteControllerWantsSwitchToAlternative(self,
                                                            response: decoded.routeResponse,
                                                            routeIndex: Int(route.getRouteIndex()),
                                                            options: decoded.routeOptions,
                                                            routeOrigin: route.getRouterOrigin())
    }

    func onRerouteDetected(forRouteRequest routeRequest: String) -> Bool {
        isCancelled = false
        latestRouteResponse = nil
        guard reroutesProactively, let delegate = delegate else { return true }
        return delegate.rerouteControllerDidDetectReroute(self)
    }

    func onRerouteReceived(forRouteResponse routeResponse: String, routeRequest: String, origin: RouterOrigin) {
        guard reroutesProactively else { return }
        
        guard let decodedRequest = Self.decode(routeRequest: routeRequest) else {
            delegate?.rerouteControllerDidFailToReroute(self, with: DirectionsError.invalidResponse(nil))
            return
        }
        
        if let latestRouteResponse = latestRouteResponse,
           decodedRequest.routeOptions == latestRouteResponse.options {
            delegate?.rerouteControllerDidRecieveReroute(self,
                                                         response: latestRouteResponse.response,
                                                         options: latestRouteResponse.options,
                                                         routeOrigin: origin)
            self.latestRouteResponse = nil
        } else {
            guard let decodedResponse = Self.decode(routeResponse: routeResponse,
                                                    routeOptions: decodedRequest.routeOptions,
                                                    credentials: decodedRequest.credentials) else {
                delegate?.rerouteControllerDidFailToReroute(self, with: DirectionsError.invalidResponse(nil))
                return
            }
            
            delegate?.rerouteControllerDidRecieveReroute(self,
                                                         response: decodedResponse,
                                                         options: decodedRequest.routeOptions,
                                                         routeOrigin: origin)
        }
    }

    func onRerouteCancelled() {
        latestRouteResponse = nil
        guard reroutesProactively else { return }
        
        delegate?.rerouteControllerDidCancelReroute(self)
    }

    func onRerouteFailed(forError error: RerouteError) {
        latestRouteResponse = nil
        guard reroutesProactively else { return }
        
        delegate?.rerouteControllerDidFailToReroute(self,
                                                    with: DirectionsError.unknown(response: nil,
                                                                                  underlying: ReroutingError(error),
                                                                                  code: nil,
                                                                                  message: error.message))
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

extension RerouteController: RerouteControllerInterface {
    func reroute(forUrl url: String, callback: @escaping RerouteCallback) {
        guard reroutesProactively && !isCancelled else {
            callback(.init(error: RerouteError(message: "Cancelled by user.",
                                               type: .cancelled)))
            return
        }
        
        guard let customRoutingProvider = customRoutingProvider else {
            callback(.init(error: RerouteError(message: "Custom rerouting triggered with no proper rerouting provider.",
                                               type: .routerError)))
            return
        }
        
        guard let routeOptions = RouteOptions(url: URL(string: url)!) else {
            callback(.init(error: RerouteError(message: "Unable to decode route request for rerouting.",
                                               type: .routerError)))
            return
        }
        
        reroutingRequest = customRoutingProvider.calculateRoutes(options: routeOptions) {result in
            switch result {
            case .failure(let error):
                callback(.init(error: RerouteError(message: error.localizedDescription,
                                                   type: .routerError)))
            case .success(let indexedRouteResponse):
                let routeResponse = indexedRouteResponse.routeResponse
                if let responseString = routeResponse.identifier {
                    self.latestRouteResponse = (routeResponse, routeOptions)
                    callback(.init(value: RerouteInfo(routeResponse: responseString,
                                                      routeRequest: url,
                                                      origin: .onboard)))
                } else {
                    callback(.init(error: RerouteError(message: "Failed to process `routeResponse`.",
                                                       type: .routerError)))
                }
            }
        }
    }

    func cancel() {
        isCancelled = true
        defaultRerouteController.cancel()
        reroutingRequest?.cancel()
    }
}
