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
public typealias IndexedRouteResponse = (routeResponse: RouteResponse, routeIndex: Int)

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
     
     - parameter routeResponse: `RouteResponse` object, containing selection of routes to follow.
     - parameter routeIndex: The index of the route within the original `RouteResponse` object.
     - parameter directions: The Directions object that created `route`.
     - parameter source: The data source for the RouteController.
     - parameter tileStoreLocation: Configuration of `TileStore` location, where Navigation tiles are stored.
     */
    init(along routeResponse: RouteResponse, routeIndex: Int, options: RouteOptions, directions: Directions, dataSource source: RouterDataSource, tileStoreLocation: TileStoreConfiguration.Location)
    
    /**
     Details about the user’s progress along the current route, leg, and step.
     */
    var routeProgress: RouteProgress { get }

    /// The route along which the user is expected to travel.
    ///
    /// You can update the route using `Router.updateRoute(with:routeOptions:)`.
    var route: Route { get }
    
    /// The `RouteResponse` containing the route along which the user is expected to travel, plus its index in this `RouteResponse`, if applicable.
    ///
    /// If you want to update the route use `Router.updateRoute(with:routeOptions:)` method.
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
    func advanceLegIndex()

    /// Replaces currently active route with the provided `IndexedRoute`.
    ///
    /// You can use this method to perform manual reroutes. `delegate` will be notified about route change via
    /// `RouterDelegate.router(router:willRerouteFrom:)` and `RouterDelegate.router(_:didRerouteAlong:at:proactive:)`
    /// methods.
    /// - Parameters:
    ///   - indexedRouteResponse: A `MapboxDirections.RouteResponse` object with a new route along with its index in routes array.
    ///   - routeOptions: Route options used to create the route. You can pass nil to reuse the `RouteOptions` from the
    ///   currently active route. If the new `indexedRoute` is for a different set of waypoints, `routeOptions` are
    ///   required.
    ///
    ///  - Important: This method can interfere with `Route.reroute(from:along:)` method. Before updating the route
    ///  manually make sure that there is no reroute running by observing `RouterDelegate.router(_:willRerouteFrom:)`
    ///  and `router(_:didRerouteAlong:at:proactive:)` `delegate` methods.
    func updateRoute(with indexedRouteResponse: IndexedRouteResponse, routeOptions: RouteOptions?)
}

protocol InternalRouter: AnyObject {
    var lastProactiveRerouteDate: Date? { get set }
    
    var lastRouteRefresh: Date? { get set }
    
    var routeTask: URLSessionDataTask? { get set }
    
    var didFindFasterRoute: Bool { get set }
    
    var lastRerouteLocation: CLLocation? { get set }
    
    func setRoute(route: Route, proactive: Bool, routeOptions: RouteOptions?)
    
    var isRerouting: Bool { get set }
    
    var isRefreshing: Bool { get set }
    
    var directions: Directions { get }
    
    var routeProgress: RouteProgress { get set }
    
    var indexedRouteResponse: IndexedRouteResponse { get set }
}

extension InternalRouter where Self: Router {
    
    func refreshAndCheckForFasterRoute(from location: CLLocation, routeProgress: RouteProgress) {
        if refreshesRoute {
            refreshRoute(from: location, legIndex: routeProgress.legIndex) {
                self.checkForFasterRoute(from: location, routeProgress: routeProgress)
            }
        } else {
            checkForFasterRoute(from: location, routeProgress: routeProgress)
        }
    }
    
    func refreshRoute(from location: CLLocation, legIndex: Int, completion: @escaping ()->()) {
        guard refreshesRoute, let routeIdentifier = indexedRouteResponse.routeResponse.identifier else {
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
        
        directions.refreshRoute(responseIdentifier: routeIdentifier, routeIndex: indexedRouteResponse.routeIndex, fromLegAtIndex: legIndex) { [weak self] (session, result) in
            defer {
                self?.isRefreshing = false
                self?.lastRouteRefresh = nil
                completion()
            }
            
            guard case let .success(response) = result, let self = self else {
                return
            }
            
            self.routeProgress.refreshRoute(with: response.route, at: location)
            
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
        
        getDirections(from: location, along: routeProgress) { [weak self] (session, result) in
            self?.isRerouting = false
            
            guard case let .success(response) = result else {
                return
            }
            guard let route = response.routes?.first else { return }
            
            self?.lastProactiveRerouteDate = nil
            
            guard let firstLeg = route.legs.first, let firstStep = firstLeg.steps.first else {
                return
            }
            
            let routeIsFaster = firstStep.expectedTravelTime >= RouteControllerMediumAlertInterval &&
                currentUpcomingManeuver == firstLeg.steps[1] && route.expectedTravelTime <= 0.9 * durationRemaining
            
            if routeIsFaster {
                var routeOptions: RouteOptions?
                if case let .route(options) = response.options {
                    routeOptions = options
                }
                
                self?.indexedRouteResponse = (response, 0)
                self?.setRoute(route: route, proactive: true, routeOptions: routeOptions)
            }
        }
    }
    
    func getDirections(from location: CLLocation, along progress: RouteProgress, completion: @escaping Directions.RouteCompletionHandler) {
        routeTask?.cancel()
        let options = progress.reroutingOptions(with: location)
        
        lastRerouteLocation = location
        
        routeTask = directions.calculateWithCache(options: options) {(session, result) in
            
            guard case let .success(response) = result else {
                return completion(session, result)
            }
            
            guard let mostSimilar = response.routes?.mostSimilar(to: progress.route) else {
                return completion(session, result)
            }
            
            var modifiedResponse = response
            modifiedResponse.routes?.removeAll { $0 == mostSimilar }
            modifiedResponse.routes?.insert(mostSimilar, at: 0)
            
            return completion(session, .success(modifiedResponse))
        }
    }
    
    func setRoute(route: Route, proactive: Bool, routeOptions: RouteOptions?) {
        let spokenInstructionIndex = routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex
        
        if proactive {
            didFindFasterRoute = true
        }
        defer {
            didFindFasterRoute = false
        }
        
        routeProgress = RouteProgress(route: route, options: routeOptions ?? routeProgress.routeOptions, legIndex: 0, spokenInstructionIndex: spokenInstructionIndex)
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
    func mostSimilar(to route: Route) -> Route? {
        let target = route.description
        return self.min { (left, right) -> Bool in
            let leftDistance = left.description.minimumEditDistance(to: target)
            let rightDistance = right.description.minimumEditDistance(to: target)
            return leftDistance < rightDistance
        }
    }
}
