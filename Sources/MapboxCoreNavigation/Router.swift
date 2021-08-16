import Foundation
import CoreLocation
import MapboxDirections

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
     */
    public let routeIndex: Int
    
    /**
     Returns a route from the `routeResponse` under given `routeIndex` if possible.
     */
    public var selectedRoute: Route? {
        guard routeResponse.routes?.count ?? 0 > routeIndex else {
            return nil
        }
        return routeResponse.routes?[routeIndex]
    }
    
    /**
     Initializes a new `IndexedRouteResponse` object.
     
     - parameter routeResponse: `RouteResponse` object, containing routes and other related info.
     - parameter routeIndex: Selected route index in an array.
     */
    public init(routeResponse: RouteResponse, routeIndex: Int) {
        self.routeResponse = routeResponse
        self.routeIndex = routeIndex
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
     - parameter routingSource: `NavigationRouter` source type, used to create route.
     - parameter source: The data source for the RouteController.
     */
    init(alongRouteAtIndex routeIndex: Int, in routeResponse: RouteResponse, options: RouteOptions, routingSource: NavigationRouter.RouterSource, dataSource source: RouterDataSource)
    
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
     The idealized user location. Snapped to the route line, if applicable, otherwise raw or nil.
     */
    var location: CLLocation? { get }
    
    /**
     The most recently received user location.
     - note: This is a raw location received from `locationManager`. To obtain an idealized location, use the `location` property.
     */
    var rawLocation: CLLocation? { get }
    
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
}

protocol InternalRouter: AnyObject {
    var lastProactiveRerouteDate: Date? { get set }
    
    var lastRouteRefresh: Date? { get set }
    
    var routeTask: NavigationRouter.RoutingRequest? { get set }
    
    var lastRerouteLocation: CLLocation? { get set }
    
    var isRerouting: Bool { get set }
    
    var isRefreshing: Bool { get set }
    
    var routingSource: NavigationRouter.RouterSource { get }
    
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
            refreshRoute(from: location, legIndex: routeProgress.legIndex) {
                self.checkForFasterRoute(from: location, routeProgress: routeProgress, router: $0)
            }
        } else {
            checkForFasterRoute(from: location, routeProgress: routeProgress)
        }
    }
    
    func refreshRoute(from location: CLLocation, legIndex: Int, completion: @escaping (NavigationRouter?)->()) {
        guard refreshesRoute else {
            completion(nil)
            return
        }
        
        guard let lastRouteRefresh = lastRouteRefresh else {
            self.lastRouteRefresh = location.timestamp
            completion(nil)
            return
        }
        
        guard location.timestamp.timeIntervalSince(lastRouteRefresh) >= RouteControllerProactiveReroutingInterval else {
            completion(nil)
            return
        }
        
        if isRefreshing {
            completion(nil)
            return
        }
        isRefreshing = true
        let router = NavigationRouter(self.routingSource)
        router.refreshRoute(indexedRouteResponse: indexedRouteResponse,
                            fromLegAtIndex: UInt32(legIndex)) { [weak self, weak router] session, result in
            defer {
                self?.isRefreshing = false
                self?.lastRouteRefresh = nil
                completion(router)
            }
            
            guard case let .success(response) = result, let self = self else {
                return
            }
            self.indexedRouteResponse = .init(routeResponse: response, routeIndex: self.indexedRouteResponse.routeIndex)
            self.routeProgress.refreshRoute(with: self.indexedRouteResponse.selectedRoute!, at: location)
            
            var userInfo = [RouteController.NotificationUserInfoKey: Any]()
            userInfo[.routeProgressKey] = self.routeProgress
            NotificationCenter.default.post(name: .routeControllerDidRefreshRoute, object: self, userInfo: userInfo)
            self.delegate?.router(self, didRefresh: self.routeProgress)
        }
    }
    
    func checkForFasterRoute(from location: CLLocation, routeProgress: RouteProgress, router: NavigationRouter? = nil) {
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
        
        calculateRoutes(from: location, along: routeProgress, router: router) { [weak self] (session, result) in
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
            var routeOptions: RouteOptions?
            if case let .route(options) = response.options {
                routeOptions = options
            }

            // Prefer the most optimal route (the first one) over the route that matched the original choice.
            let indexedRouteResponse = IndexedRouteResponse(routeResponse: response, routeIndex: 0)
            self.updateRoute(with: indexedRouteResponse,
                             routeOptions: routeOptions ?? self.routeProgress.routeOptions,
                             isProactive: true) { success in
                self.isRerouting = false
            }
        }
    }
    
    /// Like RouteCompletionHandler, but including the index of the route in the response that is most similar to the route in the route progress.
    typealias IndexedRouteCompletionHandler = (_ session: Directions.Session, _ result: Result<IndexedRouteResponse, DirectionsError>) -> Void
    
    /**
     Asynchronously calculates route response from a location along an existing route tracked by the given route progress object.
     
     - parameter origin: The origin of each resulting route.
     - parameter progress: The current route progress, along which the origin is located.
     - parameter completion: The closure to execute once the routes have been calculated. If successful, the result includes the index of the route that is most similar to the passed-in `RouteProgress.route`, which is not necessarily the first route. The first route is the route considered to be the most optimal, even if it differs from the original choice.
     */
    func calculateRoutes(from origin: CLLocation, along progress: RouteProgress, router: NavigationRouter? = nil, completion: @escaping IndexedRouteCompletionHandler) {
        routeTask?.cancel()
        let options = progress.reroutingOptions(with: origin)
        
        lastRerouteLocation = origin
        
        let router = router ?? NavigationRouter(self.routingSource)
        let taskId = router.requestRoutes(options: options) {(session, result) in
            defer { self.routeTask = nil }
            switch result {
            case .failure(let error):
                return completion(session, .failure(error))
            case .success(let response):
                guard let mostSimilarIndex = response.routes?.index(mostSimilarTo: progress.route) else {
                    return completion(session, .failure(.unableToRoute))
                }
                
                return completion(session, .success(.init(routeResponse: response, routeIndex: mostSimilarIndex)))
            }
        }
        routeTask = router.activeRequests[taskId]
    }
    
    func announceImpendingReroute(at location: CLLocation) {
        delegate?.router(self, willRerouteFrom: location)
        NotificationCenter.default.post(name: .routeControllerWillReroute, object: self, userInfo: [
            RouteController.NotificationUserInfoKey.locationKey: location,
        ])
    }
    
    func announce(reroute newRoute: Route, at location: CLLocation?, proactive: Bool) {
        var userInfo = [RouteController.NotificationUserInfoKey: Any]()
        if let location = location {
            userInfo[.locationKey] = location
        }
        userInfo[.isProactiveKey] = proactive
        NotificationCenter.default.post(name: .routeControllerDidReroute, object: self, userInfo: userInfo)
        delegate?.router(self, didRerouteAlong: routeProgress.route, at: location, proactive: proactive)
    }
}

extension Array where Element: MapboxDirections.Route {
    func index(mostSimilarTo route: Route) -> Int? {
        let target = route.description
        return enumerated().min { (left, right) -> Bool in
            let leftDistance = left.element.description.minimumEditDistance(to: target)
            let rightDistance = right.element.description.minimumEditDistance(to: target)
            return leftDistance < rightDistance
        }?.offset
    }
}
