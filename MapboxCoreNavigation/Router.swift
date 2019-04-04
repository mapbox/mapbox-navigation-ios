import Foundation
import CoreLocation
import MapboxDirections

@objc (MBRouterDataSource)
public protocol RouterDataSource {
    var locationProvider: NavigationLocationManager.Type { get }
}

@objc public protocol Router: class, CLLocationManagerDelegate {
    
    /**
     The route controller’s associated location manager.
     */
    @objc unowned var dataSource: RouterDataSource { get }
    
    /**
     The route controller’s delegate.
     */
    @objc var delegate: RouterDelegate? { get set }
    
    /**
     Intializes a new `RouteController`.
     
     - parameter route: The route to follow.
     - parameter directions: The Directions object that created `route`.
     - parameter source: The data source for the RouteController.
     */
    @objc(initWithRoute:directions:dataSource:)
    init(along route: Route, directions: Directions, dataSource source: RouterDataSource)
    
    /**
     Details about the user’s progress along the current route, leg, and step.
     */
    @objc var routeProgress: RouteProgress { get }
    
    @objc var route: Route { get set }
    
    /**
     Given a users current location, returns a Boolean whether they are currently on the route.
     
     If the user is not on the route, they should be rerouted.
     */
    @objc func userIsOnRoute(_ location: CLLocation) -> Bool
    @objc func reroute(from: CLLocation, along: RouteProgress)
    
    /**
     The idealized user location. Snapped to the route line, if applicable, otherwise raw or nil.
     */
    @objc var location: CLLocation? { get }
    
    /**
     The most recently received user location.
     - note: This is a raw location received from `locationManager`. To obtain an idealized location, use the `location` property.
     */
    @objc var rawLocation: CLLocation? { get }
    
    
    /**
     If true, the `RouteController` attempts to calculate a more optimal route for the user on an interval defined by `RouteControllerProactiveReroutingInterval`.
     */
    @objc var reroutesProactively: Bool { get }
    
    /**
     Advances the leg index.
     
     This is a convienence method provided to advance the leg index of any given router without having to worry about the internal data structure of the router.
     */
    @objc(advanceLegIndexWithLocation:)
    func advanceLegIndex(location: CLLocation)
    
    @objc optional func enableLocationRecording()
    @objc optional func disableLocationRecording()
    @objc optional func locationHistory() -> String
}

protocol InternalRouter: class {
    var lastProactiveRerouteDate: Date? { get set }
    
    var routeTask: URLSessionDataTask? { get set }
    
    var didFindFasterRoute: Bool { get set }
    
    var lastRerouteLocation: CLLocation? { get set }
    
    func setRoute(route: Route, proactive: Bool)
    
    var isRerouting: Bool { get set }
    
    var directions: Directions { get }
    
    var routeProgress: RouteProgress { get set }
}

extension InternalRouter where Self: Router {
    
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
        
        guard let lastProactiveRerouteDate = lastProactiveRerouteDate else {
            self.lastProactiveRerouteDate = location.timestamp
            return
        }
        
        // Only check every so often for a faster route.
        guard location.timestamp.timeIntervalSince(lastProactiveRerouteDate) >= RouteControllerProactiveReroutingInterval else {
            return
        }
        
        let durationRemaining = routeProgress.durationRemaining
        
        // Avoid interrupting an ongoing reroute
        if isRerouting { return }
        isRerouting = true
        
        getDirections(from: location, along: routeProgress) { [weak self] (route, error) in
            self?.isRerouting = false
            
            guard let route = route else { return }
            
            self?.lastProactiveRerouteDate = nil
            
            guard let firstLeg = route.legs.first, let firstStep = firstLeg.steps.first else {
                return
            }
            
            let routeIsFaster = firstStep.expectedTravelTime >= RouteControllerMediumAlertInterval &&
                currentUpcomingManeuver == firstLeg.steps[1] && route.expectedTravelTime <= 0.9 * durationRemaining
            
            if routeIsFaster {
                self?.setRoute(route: route, proactive: true)
                
            }
        }
    }
    
    func getDirections(from location: CLLocation, along progress: RouteProgress, completion: @escaping (_ route: Route?, _ error: Error?)->Void) {
        routeTask?.cancel()
        let options = progress.reroutingOptions(with: location)
        
        lastRerouteLocation = location
        
        routeTask = directions.calculate(options) {(waypoints, routes, error) in
            
            guard let routes = routes else {
                return completion(nil, error)
            }
            
            let mostSimilar = routes.mostSimilar(to: progress.route)
            return completion(mostSimilar ?? routes.first, error)
        }
    }
    
    func setRoute(route: Route, proactive: Bool) {
        let spokenInstructionIndex = routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex
        
        if proactive {
            didFindFasterRoute = true
            
            defer {
                didFindFasterRoute = false
            }
        }
        
        routeProgress = RouteProgress(route: route, legIndex: 0, spokenInstructionIndex: spokenInstructionIndex)
    }
    
    func announce(reroute newRoute: Route, at location: CLLocation?, proactive: Bool) {
        var userInfo = [RouteControllerNotificationUserInfoKey: Any]()
        if let location = location {
            userInfo[.locationKey] = location
        }
        userInfo[.isProactiveKey] = didFindFasterRoute
        NotificationCenter.default.post(name: .routeControllerDidReroute, object: self, userInfo: userInfo)
        delegate?.router?(self, didRerouteAlong: routeProgress.route, at: location, proactive: didFindFasterRoute)
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
