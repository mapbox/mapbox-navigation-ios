import CoreLocation
import Foundation
import MapboxDirections
import MapboxCommon
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

            defaultRerouteController.requestConfig = { [weak self] in
                guard let self,
                      let delegate = self.delegate,
                      let routeOptions = self.options(with: $0) else {
                    return $0
                }
                return NavigationSettings.shared.directions.url(forCalculating: delegate.rerouteControllerWillModify(options: routeOptions)).absoluteString
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
    private var initialOptions: RouteOptions?
    private var latestRouteResponse: (response: RouteResponse, options: RouteOptions)?
    private var isCancelled = false

    private let invalidationLock: NSLock = .init()
    private var isInvalidated = false
    
    private weak var navigator: MapboxNavigationNative.Navigator?

    func set(initialOptions: RouteOptions?) {
        self.initialOptions = initialOptions
    }

    func resetToDefaultSettings() {
        initialOptions = nil
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

    func invalidate() {
        let shouldInvalidate: Bool = invalidationLock {
            if isInvalidated { return false }

            isInvalidated = true
            return true
        }
        guard shouldInvalidate else { return }

        navigator?.removeRerouteObserver(for: self)
        navigator?.setRerouteControllerForController(defaultRerouteController.nativeInterface)
    }

    deinit {
        invalidate()
    }

    fileprivate var optionsType: RouteOptions.Type {
        initialOptions.map { Swift.type(of: $0) } ?? RouteOptions.self
    }

    fileprivate func options(with url: String) -> RouteOptions? {
        Self.decodeRouteOptions(with: url, type: optionsType)
    }
}

extension RerouteController: RerouteObserver {
    func onSwitchToAlternative(forRoute route: RouteInterface) {
        guard let decoded = Self.decode(routeRequest: route.getRequestUri(),
                                        routeResponse: route.getResponseJsonRef(),
                                        type: optionsType) else {
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
        
        guard let decodedRequest = Self.decode(routeRequest: routeRequest, type: optionsType) else {
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
            guard let responseData = routeResponse.data(using: .utf8),
                  let decodedResponse = Self.decode(routeResponse: responseData,
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
    internal func decode(routeRequest: String, routeResponse: DataRef)
    -> (routeOptions: RouteOptions, routeResponse: RouteResponse)? {
        Self.decode(routeRequest: routeRequest, routeResponse: routeResponse, type: optionsType)
    }

    static internal func decode(
        routeRequest: String,
        routeResponse: DataRef,
        type: RouteOptions.Type
    ) -> (routeOptions: RouteOptions, routeResponse: RouteResponse)? {
        var result: (routeOptions: RouteOptions, routeResponse: RouteResponse)?
        routeResponse.withData { responseData in
            result = decode(routeRequest: routeRequest,
                            routeResponse: responseData,
                            type: type)
        }
        return result
    }
    
    static internal func decode(
        routeRequest: String,
        routeResponse: Data,
        type: RouteOptions.Type
    ) -> (routeOptions: RouteOptions, routeResponse: RouteResponse)? {
        guard let decodedRequest = decode(routeRequest: routeRequest, type: type),
              let decodedResponse = decode(routeResponse: routeResponse,
                                           routeOptions: decodedRequest.routeOptions,
                                           credentials: decodedRequest.credentials) else {
            return nil
        }

        return (decodedRequest.routeOptions, decodedResponse)
    }

    static internal func decode(
        routeRequest: String,
        type: RouteOptions.Type
    ) -> (routeOptions: RouteOptions, credentials: Credentials)? {
        guard let requestURL = URL(string: routeRequest),
              let routeOptions = decodeRouteOptions(with: routeRequest, type: type) else {
                  return nil
        }

        return (routeOptions: routeOptions,
                credentials: Credentials(requestURL: requestURL))
    }

    static internal func decode(routeResponse: Data,
                                routeOptions: RouteOptions,
                                credentials: Credentials) -> RouteResponse? {
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = routeOptions
        decoder.userInfo[.credentials] = credentials

        return try? decoder.decode(RouteResponse.self,
                                   from: routeResponse)
    }

    static func decodeRouteOptions(
        with routeRequest: String,
        type: RouteOptions.Type
    ) -> RouteOptions? {
        let url = URL(string: routeRequest)
        return url?.routeOptions(with: type)
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

        guard let routeOptions = options(with: url) else {
            callback(.init(error: RerouteError(message: "Unable to decode route request for rerouting.",
                                               type: .routerError)))
            return
        }

        reroutingRequest = customRoutingProvider.calculateRoutes(options: routeOptions) { [weak self] result in
            guard let self = self else { return }

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

extension URL {
    var requestWaypoints: [MapboxDirections.Waypoint]? {
        guard pathComponents.count >= 3 else {
            return nil
        }

        let waypointsString = lastPathComponent.replacingOccurrences(of: ".json", with: "")
        let waypoints: [MapboxDirections.Waypoint] = waypointsString.components(separatedBy: ";").compactMap {
            let coordinates = $0.components(separatedBy: ",")
            guard coordinates.count == 2,
                  let latitudeString = coordinates.last,
                  let longitudeString = coordinates.first,
                  let latitude = CLLocationDegrees(latitudeString),
                  let longitude = CLLocationDegrees(longitudeString) else {
                return nil
            }
            return Waypoint(coordinate: .init(latitude: latitude,
                                              longitude: longitude))
        }

        guard waypoints.count >= 2 else {
            return nil
        }
        return waypoints
    }

    var profileIdentifier: ProfileIdentifier? {
        ProfileIdentifier(rawValue: pathComponents.dropLast().suffix(2).joined(separator: "/"))
    }

    func routeOptions(with type: RouteOptions.Type) -> RouteOptions? {
        guard let profileIdentifier = self.profileIdentifier,
              let waypoints = self.requestWaypoints else {
            return nil
        }
        let queryItems = URLComponents(url: self, resolvingAgainstBaseURL: true)?.queryItems
        return type.init(waypoints: waypoints, profileIdentifier: profileIdentifier, queryItems: queryItems)
    }
}
