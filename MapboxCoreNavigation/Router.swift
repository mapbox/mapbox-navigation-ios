import Foundation
import CoreLocation
import MapboxDirections

/**
 A router data source, also known as a location manager, supplies location data to a `Router` instance. For example, a `MapboxNavigationService` supplies location data to a `RouteController` or `LegacyRouteController`.
 */
public protocol RouterDataSource: class {
    /**
     The location provider for the `Router.` This class is designated as the object that will provide location updates when requested.
     */
    var locationProvider: NavigationLocationManager.Type { get }
}

/**
 A route and its index in a `RouteResponse` that sorts routes from most optimal to least optimal.
 */
public typealias IndexedRoute = (Route, Int)

/**
 A class conforming to the `Router` protocol tracks the user’s progress as they travel along a predetermined route. It calls methods on its `delegate`, which conforms to the `RouterDelegate` protocol, whenever significant events or decision points occur along the route. Despite its name, this protocol does not define the interface of a routing engine.
 
 There are two concrete implementations of the `Router` protocol. `RouteController`, the default implementation, is capable of client-side routing and depends on the Mapbox Navigation Native framework. `LegacyRouteController` is an alternative implementation that does not have this dependency but must be used in conjunction with the Mapbox Directions API over a network connection.
 */
public protocol Router: class, CLLocationManagerDelegate {
    /**
     The route controller’s associated location manager.
     */
    var dataSource: RouterDataSource { get }
    
    /**
     The route controller’s delegate.
     */
    var delegate: RouterDelegate? { get set }

    var supportsElectronicHorizon: Bool { get }
    var electronicHorizonDelegate: ElectronicHorizonDelegate? { get set }
    
    /**
     Intializes a new `RouteController`.
     
     - parameter route: The route to follow.
     - parameter routeIndex: The index of the route within the original `RouteResponse` object.
     - parameter directions: The Directions object that created `route`.
     - parameter source: The data source for the RouteController.
     */
    init(along route: Route, routeIndex: Int, options: RouteOptions, directions: Directions, dataSource source: RouterDataSource)
    
    /**
     Details about the user’s progress along the current route, leg, and step.
     */
    var routeProgress: RouteProgress { get }
    
    var indexedRoute: IndexedRoute { get set }
    
    var route: Route { get }
    
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
    
    func enableLocationRecording()
    func disableLocationRecording()
    func locationHistory() -> String?
}

protocol InternalRouter: class {
    var lastProactiveRerouteDate: Date? { get set }
    
    var lastRouteRefresh: Date? { get set }
    
    var routeTask: URLSessionDataTask? { get set }
    
    var didFindFasterRoute: Bool { get set }
    
    var lastRerouteLocation: CLLocation? { get set }
    
    func setRoute(route: Route, routeIndex: Int, proactive: Bool)
    
    var isRerouting: Bool { get set }
    
    var isRefreshing: Bool { get set }
    
    var directions: Directions { get }
    
    var routeProgress: RouteProgress { get set }
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
        guard refreshesRoute, let routeIdentifier = route.routeIdentifier else {
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
        
        directions.refreshRoute(responseIdentifier: routeIdentifier, routeIndex: indexedRoute.1, fromLegAtIndex: legIndex) { [weak self] (session, result) in
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
                self?.setRoute(route: route, routeIndex: 0, proactive: true)
            }
        }
    }
    
    func getDirections(from location: CLLocation, along progress: RouteProgress, completion: @escaping Directions.RouteCompletionHandler) {
        routeTask?.cancel()
        let options = progress.reroutingOptions(with: location)
        
        lastRerouteLocation = location
        
        routeTask = directions.calculate(options) {(session, result) in
            
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
    
    func setRoute(route: Route, routeIndex: Int, proactive: Bool) {
        let spokenInstructionIndex = routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex
        
        if proactive {
            didFindFasterRoute = true
        }
        defer {
            didFindFasterRoute = false
        }
        
        routeProgress = RouteProgress(route: route, routeIndex: routeIndex, options: routeProgress.routeOptions, legIndex: 0, spokenInstructionIndex: spokenInstructionIndex)
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
