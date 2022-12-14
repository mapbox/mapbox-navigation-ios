import Foundation
import CoreLocation
import MapboxDirections
import MapboxNavigationNative

/**
 A router data source, also known as a location manager, supplies location data to a `Router` instance. For example, a `MapboxNavigationService` supplies location data to a `RouteController` or `LegacyRouteController`.
 */
public protocol RouterDataSource: AnyObject {
    /**
     The location provider for the `Router.` This class is designated as the object that will provide location updates when requested.
     */
    var locationManagerType: NavigationLocationManager.Type { get }
}

/**
 A `RouteResponse` object that sorts routes from most optimal to least optimal and selected route index in it.
 */
public struct IndexedRouteResponse {
    /**
     `RouteResponse` object, containing selection of routes to follow.
     */
    public let routeResponse: RouteResponse
    /**
     The index of the selected route within the `routeResponse`.
     
     Updating this value after turn-by-turn navigation has started will have no effect. To actually update the route, use `Router.updateRoute(with:routeOptions:completion:)` method from corresponding `router`.
     */
    public var routeIndex: Int
    
    /**
     Returns a route from the `routeResponse` under given `routeIndex` if possible.
     */
    public var currentRoute: Route? {
        guard let routes = routeResponse.routes,
              routes.count > routeIndex else {
            return nil
        }
        return routeResponse.routes?[routeIndex]
    }
    
    /**
     Parses routes in the current response, accounting `routeIndex` to be pointing to the primary route, while all the others being `AlternativeRoute`s.
     
     - returns: Array of `AlternativeRoutes` containing relative information to `currentRoute`.
     */
    public func parseAlternativeRoutes() -> [AlternativeRoute] {
        guard let mainRoute = currentRoute,
              let routesData = routesData(routeParserType: RouteParser.self) else {
            return []
        }
        
        let alternatives = routesData.alternativeRoutes().compactMap {
            AlternativeRoute(mainRoute: mainRoute,
                             alternativeRoute: $0)
        }
        return alternatives
    }
    
    func routesData(routeParserType: RouteParser.Type) -> RoutesData? {
        let routeOptions = validatedRouteOptions
        
        let encoder = JSONEncoder()
        encoder.userInfo[.options] = routeOptions
        guard let routeData = try? encoder.encode(routeResponse),
              let routeJSONString = String(data: routeData, encoding: .utf8) else {
                  return nil
        }
        
        let routeRequest = Directions(credentials: routeResponse.credentials)
            .url(forCalculating: routeOptions).absoluteString
        
        let parsedRoutes = routeParserType.parseDirectionsResponse(forResponse: routeJSONString,
                                                                   request: routeRequest,
                                                                   routeOrigin: responseOrigin)
        if parsedRoutes.isValue(),
           var routes = parsedRoutes.value as? [RouteInterface],
           routes.indices.contains(routeIndex) {
            return routeParserType.createRoutesData(forPrimaryRoute: routes.remove(at: routeIndex),
                                                    alternativeRoutes: routes)
        }
        return nil
    }
    
    /**
     Initializes a new `IndexedRouteResponse` object.
     
     - parameter routeResponse: `RouteResponse` object, containing routes and other related info.
     - parameter routeIndex: Selected route index in an array.
     */
    public init(routeResponse: RouteResponse, routeIndex: Int) {
        self.init(routeResponse: routeResponse,
                  routeIndex: routeIndex,
                  responseOrigin: .custom)
    }
    
    /**
     Describes the origin of current route response.
     
     Used by `Navigator` for better understanding current state and various features functioning.
     */
    internal let responseOrigin: RouterOrigin
    
    init(routeResponse: RouteResponse,
         routeIndex: Int,
         responseOrigin: RouterOrigin) {
        self.routeResponse = routeResponse
        self.routeIndex = routeIndex
        self.responseOrigin = responseOrigin
    }
    
    internal var validatedRouteOptions: RouteOptions {
        switch routeResponse.options {
        case let .match(matchOptions):
            return RouteOptions(matchOptions: matchOptions)
        case let .route(options):
            return options
        }
    }
}

/**
 A closure to be called when `RouteLeg` was changed.
 
 - parameter result: Result, which in case of successfully changed leg contains the most recent
 `RouteProgress` and error, in case of failure.
 */
public typealias AdvanceLegCompletionHandler = (_ result: Result<RouteProgress, Error>) -> Void

/**
 A class conforming to the `Router` protocol tracks the user’s progress as they travel along a predetermined route. It calls methods on its `delegate`, which conforms to the `RouterDelegate` protocol, whenever significant events or decision points occur along the route. Despite its name, this protocol does not define the interface of a routing engine.
 
 There are two concrete implementations of the `Router` protocol. `RouteController`, the default implementation, is capable of client-side routing and depends on the Mapbox Navigation Native framework. `LegacyRouteController` is an alternative implementation that does not have this dependency but must be used in conjunction with the Mapbox Directions API over a network connection.
 */
public protocol Router: CLLocationManagerDelegate {
    /**
     The route controller’s associated location manager.
     */
    var dataSource: RouterDataSource { get }
    
    /**
     The route controller’s delegate.
     */
    var delegate: RouterDelegate? { get set }
    
    /**
     Intializes a new `RouteController`.
     
     - parameter routeIndex: The index of the route within the original `RouteResponse` object.
     - parameter routeResponse: `RouteResponse` object, containing selection of routes to follow.
     - parameter routingProvider: `RoutingProvider`, used to create a route during refreshing or rerouting.
     - parameter source: The data source for the RouteController.
     */
    @available(*, deprecated, renamed: "init(indexedRouteResponse:customRoutingProvider:dataSource:)")
    init(alongRouteAtIndex routeIndex: Int,
         in routeResponse: RouteResponse,
         options: RouteOptions,
         routingProvider: RoutingProvider,
         dataSource source: RouterDataSource)
    
    /**
     Intializes a new `RouteController`.
     
     - parameter routeIndex: The index of the route within the original `RouteResponse` object.
     - parameter routeResponse: `RouteResponse` object, containing selection of routes to follow.
     - parameter customRoutingProvider: Custom `RoutingProvider`, used to create a route during refreshing or rerouting.
     - parameter source: The data source for the RouteController.
     */
    @available(*, deprecated, renamed: "init(indexedRouteResponse:customRoutingProvider:dataSource:)")
    init(alongRouteAtIndex routeIndex: Int,
         in routeResponse: RouteResponse,
         options: RouteOptions,
         customRoutingProvider: RoutingProvider?,
         dataSource source: RouterDataSource)
    
    /**
     Intializes a new `RouteController`.
     
     - parameter indexedRouteResponse: `IndexedRouteResponse` object, containing selection of routes to follow.
     - parameter customRoutingProvider: Custom `RoutingProvider`, used to create a route during refreshing or rerouting.
     - parameter source: The data source for the RouteController.
     */
    init(indexedRouteResponse: IndexedRouteResponse,
         customRoutingProvider: RoutingProvider?,
         dataSource source: RouterDataSource)
    
    /**
     `RoutingProvider`, used to create a route during refreshing or rerouting.
     */
    @available(*, deprecated, renamed: "customRoutingProvider")
    var routingProvider: RoutingProvider { get }
    
    /**
     Custom `RoutingProvider`, used to create a route during refreshing or rerouting.
     */
    var customRoutingProvider: RoutingProvider? { get }
    /**
     Details about the user’s progress along the current route, leg, and step.
     */
    var routeProgress: RouteProgress { get }

    /// The route along which the user is expected to travel.
    ///
    /// You can update the route using `Router.updateRoute(with:routeOptions:completion:)`.
    var route: Route { get }
    
    /// The `RouteResponse` containing the route along which the user is expected to travel, plus its index in this `RouteResponse`, if applicable.
    ///
    /// If you want to update the route use `Router.updateRoute(with:routeOptions:completion:)` method.
    var indexedRouteResponse: IndexedRouteResponse { get }
    
    /**
     Given a users current location, returns a Boolean whether they are currently on the route.
     
     If the user is not on the route, they should be rerouted.
     */
    func userIsOnRoute(_ location: CLLocation) -> Bool
    func reroute(from: CLLocation, along: RouteProgress)
    
    /**
     A radius around the current user position in which the API will avoid returning any significant maneuvers when rerouting.
     
     Provided `TimeInterval` value will be converted to meters using current speed. Default value is `8 seconds`.
     */
    var initialManeuverAvoidanceRadius: TimeInterval { get set }
    
    /**
     The idealized user location. Snapped to the route line, if applicable, otherwise raw or nil.
     */
    var location: CLLocation? { get }
    
    /**
     The most recently received user location.
     - note: This is a raw location received from `locationManager`. To obtain an idealized location, use the `location` property.
     */
    var rawLocation: CLLocation? { get }
    
    /**
     The most recently received user heading, if any.
     */
    var heading: CLHeading? { get }
    
    /**
     If true, the `RouteController` attempts to calculate a more optimal route for the user on an interval defined by `RouteControllerProactiveReroutingInterval`. If `refreshesRoute` is enabled too, reroute attempt will be fired after route refreshing.
     */
    var reroutesProactively: Bool { get set }
    
    /**
     If true, the `RouteController` attempts to update ETA and route congestion on an interval defined by `RouteControllerProactiveReroutingInterval`.
     
     Refreshing will be used only if route's mode of transportation profile is set to `.automobileAvoidingTraffic`. If `reroutesProactively` is enabled too, rerouting will be checked after route is refreshed.
     */
    var refreshesRoute: Bool { get set }
    
    /**
     Advances the leg index.
     
     This is a convienence method provided to advance the leg index of any given router without having to worry about the internal data structure of the router.
     */
    func advanceLegIndex(completionHandler: AdvanceLegCompletionHandler?)

    /// Asynchronously replaces currently active route with the provided `IndexedRouteResponse`.
    ///
    /// You can use this method to perform manual reroutes. `delegate` will be notified about route change via
    /// `RouterDelegate.router(router:willRerouteFrom:)` and `RouterDelegate.router(_:didRerouteAlong:at:proactive:)`
    /// methods.
    /// - Parameters:
    ///   - indexedRouteResponse: A `MapboxDirections.RouteResponse` object with a new route along with its index in
    ///   routes array.
    ///   - routeOptions: Route options used to create the route. You can pass nil to reuse the `RouteOptions` from the
    ///   currently active route. If the new `indexedRoute` is for a different set of waypoints, `routeOptions` are
    ///   required.
    ///   - completion: A completion that will be called when when a new route is applied with a boolean indicating
    ///   whether the change was successful. Until completion is called `routeProgress` will represent the old route.
    ///
    ///  - Important: This method can interfere with `Route.reroute(from:along:)` method. Before updating the route
    ///  manually make sure that there is no reroute running by observing `RouterDelegate.router(_:willRerouteFrom:)`
    ///  and `router(_:didRerouteAlong:at:proactive:)` `delegate` methods.
    ///
    ///  - Important: Updating the route can have an impact on your usage costs.
    ///  From more info read the [Pricing Guide](https://docs.mapbox.com/ios/beta/navigation/guides/pricing/).
    func updateRoute(with indexedRouteResponse: IndexedRouteResponse,
                     routeOptions: RouteOptions?,
                     completion: ((Bool) -> Void)?)
    
    /// Forcefully stop navigation process without ability to continue it.
    ///
    /// Use this method to indicate that you no longer need navigation experience for current session/UI.
    /// After finishing, `Router` will not be able to update route, route leg, issue a reroute or do any other update, related to route traversing.
    func finishRouting()
    
    /// `AlternativeRoute`s user might take during this trip to reach the destination using another road.
    ///
    /// Array contents are updated automatically duting the trip. Alternative routes may be slower or longer then the main route.
    /// To get updates, subscribe to `RouterDelegate.router(_:didUpdateAlternatives:removedAlternatives:)` or `Notification.Name.routeControllerDidUpdateAlternatives` notification.
    var continuousAlternatives: [AlternativeRoute] { get }
}

protocol InternalRouter: AnyObject {
    var lastProactiveRerouteDate: Date? { get set }
    
    var lastRouteRefresh: Date? { get set }
    
    var routeTask: NavigationProviderRequest? { get set }
    
    var lastRerouteLocation: CLLocation? { get set }
    
    var isRerouting: Bool { get set }
    
    var isRefreshing: Bool { get set }
    
    var resolvedRoutingProvider: RoutingProvider { get }
    
    var routeProgress: RouteProgress { get }
    
    var indexedRouteResponse: IndexedRouteResponse { get set }

    func updateRoute(with indexedRouteResponse: IndexedRouteResponse,
                     routeOptions: RouteOptions?,
                     isProactive: Bool,
                     completion: ((Bool) -> Void)?)
}

extension InternalRouter where Self: Router {
    
    func refreshAndCheckForFasterRoute(from location: CLLocation, routeProgress: RouteProgress) {
        if refreshesRoute {
            refreshRoute(from: location, legIndex: routeProgress.legIndex, routeShapeIndex: routeProgress.shapeIndex, legShapeIndex: routeProgress.currentLegProgress.shapeIndex) { [weak self] in
                self?.checkForFasterRoute(from: location, routeProgress: routeProgress)
            }
        } else {
            checkForFasterRoute(from: location, routeProgress: routeProgress)
        }
    }
    
    private func refreshRoute(from location: CLLocation, legIndex: Int, routeShapeIndex: Int, legShapeIndex: Int, completion: @escaping ()->()) {
        guard refreshesRoute else {
            completion()
            return
        }
        
        guard let lastRouteRefresh = lastRouteRefresh else {
            self.lastRouteRefresh = location.timestamp
            completion()
            return
        }
        
        guard location.timestamp.timeIntervalSince(lastRouteRefresh) >= RouteControllerProactiveReroutingInterval else {
            completion()
            return
        }
        
        if isRefreshing {
            completion()
            return
        }
        isRefreshing = true
        let routeIndex = indexedRouteResponse.routeIndex
        let routeOrigin = indexedRouteResponse.responseOrigin
        resolvedRoutingProvider.refreshRoute(indexedRouteResponse: indexedRouteResponse,
                                             fromLegAtIndex: UInt32(legIndex),
                                             currentRouteShapeIndex: routeShapeIndex,
                                             currentLegShapeIndex: legShapeIndex) { [weak self] session, result in
            defer {
                self?.isRefreshing = false
                self?.lastRouteRefresh = nil
                completion()
            }
            
            guard case let .success(response) = result, let self = self else {
                return
            }
            guard response.identifier == self.indexedRouteResponse.routeResponse.identifier else {
                return
            }
            self.indexedRouteResponse = .init(routeResponse: response,
                                              routeIndex: routeIndex,
                                              responseOrigin: routeOrigin)
            
            guard let currentRoute = self.indexedRouteResponse.currentRoute else {
                assertionFailure("Refreshed `RouteResponse` did not contain required `routeIndex`!")
                return
            }
            
            self.routeProgress.refreshRoute(with: currentRoute,
                                            at: self.location ?? location,
                                            legIndex: legIndex,
                                            legShapeIndex: legShapeIndex)
            
            var userInfo = [RouteController.NotificationUserInfoKey: Any]()
            userInfo[.routeProgressKey] = self.routeProgress
            NotificationCenter.default.post(name: .routeControllerDidRefreshRoute, object: self, userInfo: userInfo)
            self.delegate?.router(self, didRefresh: self.routeProgress)
        }
    }
    
    func checkForFasterRoute(from location: CLLocation, routeProgress: RouteProgress) {
        // Check for faster route given users current location
        guard reroutesProactively else { return }
        
        // Only check for faster alternatives if the user has plenty of time left on the route.
        guard routeProgress.durationRemaining > RouteControllerMinimumDurationRemainingForProactiveRerouting else { return }
        // If the user is approaching a maneuver, don't check for a faster alternatives
        guard routeProgress.currentLegProgress.currentStepProgress.durationRemaining > RouteControllerMediumAlertInterval else { return }
        
        guard let currentUpcomingManeuver = routeProgress.currentLegProgress.upcomingStep else {
            return
        }
        
        guard let lastRouteValidationDate = lastProactiveRerouteDate else {
            self.lastProactiveRerouteDate = location.timestamp
            return
        }
        
        // Only check every so often for a faster route.
        guard location.timestamp.timeIntervalSince(lastRouteValidationDate) >= RouteControllerProactiveReroutingInterval else {
            return
        }
        
        let durationRemaining = routeProgress.durationRemaining
        
        // Avoid interrupting an ongoing reroute
        if isRerouting { return }
        isRerouting = true
        
        calculateRoutes(from: location, along: routeProgress) { [weak self] (result) in
            guard let self = self else { return }

            guard case let .success(indexedResponse) = result else {
                self.isRerouting = false; return
            }
            let response = indexedResponse.routeResponse
            guard let route = response.routes?.first else {
                self.isRerouting = false; return
            }
            
            self.lastProactiveRerouteDate = nil
            
            guard let firstLeg = route.legs.first, let firstStep = firstLeg.steps.first else {
                self.isRerouting = false; return
            }
            
            let routeIsFaster = firstStep.expectedTravelTime >= RouteControllerMediumAlertInterval &&
                currentUpcomingManeuver == firstLeg.steps[1] && route.expectedTravelTime <= 0.9 * durationRemaining
            
            guard routeIsFaster else {
                self.isRerouting = false; return
            }
            
            let completion = { [weak self] in
                guard let self = self else { return }
                var routeOptions: RouteOptions?
                if case let .route(options) = response.options {
                    routeOptions = options
                }

                onMainAsync {
                    // Prefer the most optimal route (the first one) over the route that matched the original choice.
                    self.updateRoute(with: indexedResponse,
                                     routeOptions: routeOptions ?? self.routeProgress.routeOptions,
                                     isProactive: true) { [weak self] success in
                        self?.isRerouting = false
                    }
                }
            }
            
            if let delegate = self.delegate {
                delegate.router(self,
                                shouldProactivelyRerouteFrom: location,
                                to: route,
                                completion: completion)
            } else if RouteController.DefaultBehavior.shouldProactivelyRerouteFromLocation {
                completion()
            }
        }
    }
    
    /// Like RouteCompletionHandler, but including the index of the route in the response that is most similar to the route in the route progress.
    typealias IndexedRouteCompletionHandler = (_ result: Result<IndexedRouteResponse, DirectionsError>) -> Void
    
    /**
     Asynchronously calculates route response from a location along an existing route tracked by the given route progress object.
     
     - parameter origin: The origin of each resulting route.
     - parameter progress: The current route progress, along which the origin is located.
     - parameter completion: The closure to execute once the routes have been calculated. If successful, the result includes the index of the route that is most similar to the passed-in `RouteProgress.route`, which is not necessarily the first route. The first route is the route considered to be the most optimal, even if it differs from the original choice.
     */
    func calculateRoutes(from origin: CLLocation, along progress: RouteProgress, completion: @escaping IndexedRouteCompletionHandler) {
        routeTask?.cancel()
        let options = progress.reroutingOptions(from: origin)
        
        // https://github.com/mapbox/mapbox-navigation-ios/issues/3966
        if isRerouting && (options.profileIdentifier == .automobile || options.profileIdentifier == .automobileAvoidingTraffic) {
            options.initialManeuverAvoidanceRadius = initialManeuverAvoidanceRadius * origin.speed
        }
        
        lastRerouteLocation = origin
        
        routeTask = resolvedRoutingProvider.calculateRoutes(options: options) { [weak self] (result) in
            guard let self = self else { return }
            defer { self.routeTask = nil }
            switch result {
            case .failure(let error):
                return completion(.failure(error))
            case .success(var response):
                guard let mostSimilarIndex = response.routeResponse.routes?.index(mostSimilarTo: progress.route) else {
                    return completion(.failure(.unableToRoute))
                }
                response.routeIndex = mostSimilarIndex
                return completion(.success(response))
            }
        }
    }
    
    func announceImpendingReroute(at location: CLLocation) {
        delegate?.router(self, willRerouteFrom: location)
        
        var userInfo: [RouteController.NotificationUserInfoKey: Any] = [
            .locationKey: location,
        ]
        userInfo[.headingKey] = heading
        
        NotificationCenter.default.post(name: .routeControllerWillReroute, object: self, userInfo: userInfo)
    }
    
    func announce(reroute newRoute: Route, at location: CLLocation?, proactive: Bool) {
        var userInfo = [RouteController.NotificationUserInfoKey: Any]()
        userInfo[.locationKey] = location
        userInfo[.headingKey] = heading
        userInfo[.isProactiveKey] = proactive
        NotificationCenter.default.post(name: .routeControllerDidReroute, object: self, userInfo: userInfo)
        delegate?.router(self, didRerouteAlong: routeProgress.route, at: location, proactive: proactive)
    }
}

extension Array where Element: MapboxDirections.Route {
    func index(mostSimilarTo route: Route) -> Int? {
        let target = route.description
        
        guard let bestCandidate = map({
            (route: $0, editDistance: $0.description.minimumEditDistance(to: target))
        }).enumerated().min(by: { $0.element.editDistance < $1.element.editDistance }) else { return nil }

        // If the most similar route is still more than 50% different from the original route,
        // we fallback to the fastest route which index is 0.
        let totalLength = Double(bestCandidate.element.route.description.count + target.description.count)
        guard totalLength > 0 else { return 0 }
        let differenceScore = Double(bestCandidate.element.editDistance) / totalLength
        // Comparing to 0.25 as for "replacing the half of the string", since we add target and candidate lengths together
        // Algorithm proposal: https://github.com/mapbox/mapbox-navigation-ios/pull/3664#discussion_r772194977
        guard differenceScore < 0.25 else { return 0 }

        return bestCandidate.offset
    }
}
