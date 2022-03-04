import Foundation
import MapboxDirections
@_implementationOnly import MapboxNavigationNative_Private

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
            config.avoidManeuverSeconds?.doubleValue ?? Self.DefaultManeuverAvoidanceRadius
        }
        set {
            config.avoidManeuverSeconds = NSNumber(value: newValue)
        }
    }
    
    var customRoutingProvider: RoutingProvider? = nil {
        didSet {
            self.navigator?.setRerouteControllerForController(
                customRoutingProvider.map { _ in self } ?? defaultRerouteController
            )
        }
    }
    
    private var config: NavigatorConfig
    
    // MARK: Reporting Data
    
    weak var delegate: ReroutingObserverDelegate?
    
    func userIsOnRoute() -> Bool {
        return !rerouteDetector.isReroute()
    }
    
    func forceReroute() {
        rerouteDetector.forceReroute()
    }
    
    // MARK: Internal State Management
    
    private let defaultRerouteController: RerouteControllerInterface
    private let rerouteDetector: RerouteDetectorInterface
    
    private var reroutingRequest: NavigationProviderRequest?
    private var recentRouteResponse: (response: RouteResponse, options: RouteOptions)?
    private var isCancelled = false
    
    private weak var navigator: MapboxNavigationNative.Navigator?
    
    func resetToDefaultSettings() {
        reroutesProactively = true
        isCancelled = false
        config.avoidManeuverSeconds = NSNumber(value: Self.DefaultManeuverAvoidanceRadius)
        customRoutingProvider = nil
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
        self.navigator?.setRerouteControllerForController(defaultRerouteController)
    }
}

extension RerouteController: RerouteObserver {
    
    func onSwitchToAlternative(forAlternativeId alternativeId: UInt32,
                               routeResponse: String,
                               routeRequest: String,
                               origin: RouterOrigin) {
        print(">>> \(#function)")
        guard let decoded = Navigator.decode(routeRequest: routeRequest, routeResponse: routeResponse) else {
            return
        }
        
        delegate?.rerouteControllerWantsSwitchToAlternative(self,
                                                            response: decoded.routeResponse,
                                                            options: decoded.routeOptions)
    }
    
    func onRerouteDetected(forRouteRequest routeRequest: String) {
        print(">>> \(#function)")
        isCancelled = false
        recentRouteResponse = nil
        guard reroutesProactively else { return }
        delegate?.rerouteControllerDidDetectReroute(self)
    }
    
    func onRerouteReceived(forRouteResponse routeResponse: String, routeRequest: String, origin: RouterOrigin) {
        guard reroutesProactively else { return }
        
        guard let decodedRequest = Navigator.decode(routeRequest: routeRequest) else {
            delegate?.rerouteControllerDidFailToReroute(self, with: ReroutingError.decodingError)
            return
        }
        
        if let recentRouteResponse = recentRouteResponse,
           decodedRequest.routeOptions == recentRouteResponse.options {
            delegate?.rerouteControllerDidRecieveReroute(self,
                                                         response: recentRouteResponse.response,
                                                         options: recentRouteResponse.options)
        } else {
            guard let decodedResponse = Navigator.decode(routeResponse: routeResponse,
                                                         routeOptions: decodedRequest.routeOptions,
                                                         credentials: decodedRequest.credentials) else {
                delegate?.rerouteControllerDidFailToReroute(self, with: ReroutingError.decodingError)
                return
            }
            
            delegate?.rerouteControllerDidRecieveReroute(self,
                                                         response: decodedResponse,
                                                         options: decodedRequest.routeOptions)
        }
    }
    
    func onRerouteCancelled() {
        print(">>> \(#function)")
        recentRouteResponse = nil
        guard reroutesProactively else { return }
        
        delegate?.rerouteControllerDidCancelReroute(self)
    }
    
    func onRerouteFailed(forError error: RerouteError) {
        print(">>> \(#function)")
        recentRouteResponse = nil
        guard reroutesProactively else { return }
        
        delegate?.rerouteControllerDidFailToReroute(self, with: ReroutingError(error))
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
        
        guard let requestURL = URL(string: url),
              let routeOptions = RouteOptions(url: requestURL) else {
                  callback(.init(error: RerouteError(message: "Could not decode request URL string into valid Options object.",
                                                     type: .wrongRequest)))
            return
        }
        
        reroutingRequest = customRoutingProvider.calculateRoutes(options: routeOptions) { session, result in
            switch result {
            case .failure(let error):
                callback(.init(error: RerouteError(message: error.localizedDescription,
                                                   type: .routerError)))
            case .success(let routeResponse):
                if let responseString = routeResponse.identifier {
                    self.recentRouteResponse = (routeResponse, routeOptions)
                    callback(.init(value: RerouteInfo(routeResponse: responseString,
                                                                                    routeRequest: url,
                                                                                    origin: .onboard)))
                } else {
                    callback(.init(value: RerouteError(message: "Failed to process `routeResponse`.",
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
