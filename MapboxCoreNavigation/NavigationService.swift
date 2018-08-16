import Foundation
import CoreLocation
import MapboxDirections

@objc public protocol NavigationServiceDelegate: RouterDelegate, TunnelIntersectionManagerDelegate {}
@objc(MBNavigationService)
public protocol NavigationService: CLLocationManagerDelegate, EventsManagerDataSource {
    var locationManager: NavigationLocationManager { get }
    var router: Router { get }
    var eventsManager: EventsManager! { get }
    var route: Route { get set }
    weak var delegate: NavigationServiceDelegate? { get set }
    
    func start()
    func stop()
    func endNavigation(feedback: EndOfRouteFeedback?)
}

@objc(MBNavigationService)
public class MapboxNavigationService: NSObject, NavigationService {
    public var locationManager: NavigationLocationManager
    var directionsService: Directions
    public var router: Router
    public var eventsManager: EventsManager!
    public weak var delegate: NavigationServiceDelegate?
    
    @objc convenience init(route: Route) {
        self.init(route: route, directions: nil, locationSource: nil, eventsManager: nil)
    }
    
    @objc required public init(route: Route,
                  directions directionsOverride: Directions? = nil,
                  locationSource locationOverride: NavigationLocationManager? = nil,
                  eventsManager eventsOverride: EventsManager.Type? = nil)
    {
        locationManager = locationOverride ?? NavigationLocationManager()
        directionsService = directionsOverride ?? Directions.shared
        router = RouteController(along: route, directions: directionsService, locationManager: locationManager)
        super.init()
        let eventType = eventsOverride ?? EventsManager.self
        eventsManager = eventType.init(dataSource: self, accessToken: route.accessToken)
        locationManager.activityType = route.routeOptions.activityType
        
        bootstrapEvents(with: router)
        
        
        router.delegate = self
        locationManager.delegate = self
    }
    
    public var route: Route {
        get {
            return router.route
        }
        set {
            router.route = newValue
        }
    }
    public func start() {
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
    }
    
    public func stop() {
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
    }
    public func endNavigation(feedback: EndOfRouteFeedback? = nil) {
        eventsManager.sendCancelEvent(rating: feedback?.rating, comment: feedback?.comment)
        stop()
    }

    private func bootstrapEvents(with router: Router) {
        eventsManager.dataSource = self
        eventsManager.resetSession()
        eventsManager.start()
    }
    
}

extension MapboxNavigationService: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        router.locationManager?(manager, didUpdateHeading: newHeading)
    }
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //update the events manager with the received locations
        eventsManager.record(locations: locations)
        
        //feed the location update to the router
        router.locationManager?(manager, didUpdateLocations: locations)
    }
}

//MARK: - RouteControllerDelegate
extension MapboxNavigationService: RouteControllerDelegate {
    typealias Default = RouteController.DefaultBehavior
    
    public func routeController(_ routeController: RouteController, willRerouteFrom location: CLLocation) {
        
        //save any progress made by the router until now
        eventsManager.enqueueRerouteEvent()
        eventsManager.incrementDistanceTraveled(by: routeController.routeProgress.distanceTraveled)
        
        //notify our consumer
        delegate?.routeController?(routeController, willRerouteFrom: location)
    }
    public func routeController(_ routeController: RouteController, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        
        //notify the events manager that the route has changed
        eventsManager.reportReroute(progress: routeController.routeProgress, proactive: proactive)
        
        //notify our consumer
        delegate?.routeController?(routeController, didRerouteAlong: route, at: location, proactive: proactive)
    }
    public func routeController(_ routeController: RouteController, didFailToRerouteWith error: Error) {
        delegate?.routeController?(routeController, didFailToRerouteWith: error)
    }
    public func routeController(_ routeController: RouteController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        
        //notify the events manager of the progress update
        eventsManager.update(progress: progress)
        
        //pass the update on to consumers
        delegate?.routeController?(routeController, didUpdate: progress, with: location, rawLocation: rawLocation)
    }
    
    //MARK: Questions
    public func routeController(_ routeController: RouteController, shouldRerouteFrom location: CLLocation) -> Bool {
        return delegate?.routeController?(routeController, shouldRerouteFrom: location) ?? Default.shouldRerouteFromLocation
    }
    public func routeController(_ routeController: RouteController, shouldDiscard location: CLLocation) -> Bool {
        return delegate?.routeController?(routeController,shouldDiscard: location) ?? Default.shouldDiscardLocation
    }
    public func routeController(_ routeController: RouteController, didArriveAt waypoint: Waypoint) -> Bool {
        
        //Notify the events manager that we've arrived at a waypoint
        eventsManager.arriveAtWaypoint()
        
        return delegate?.routeController?(routeController, didArriveAt: waypoint) ?? Default.didArriveAtWaypoint
    }
    public func routeController(_ routeController: RouteController, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool {
        return delegate?.routeController?(routeController, shouldPreventReroutesWhenArrivingAt: waypoint) ?? Default.shouldPreventReroutesWhenArrivingAtWaypoint
    }
    public func routeControllerShouldDisableBatteryMonitoring(_ routeController: RouteController) -> Bool {
        return delegate?.routeControllerShouldDisableBatteryMonitoring?(routeController) ?? Default.shouldDisableBatteryMonitoring
    }
}

//MARK: EventsManagerDataSource Logic
extension MapboxNavigationService {
    public var locationSource: LocationSource {
        switch locationManager {
        case is SimulatedLocationManager:
            return .simulated
        default:
            return .device
        }
    }
    
    public var routeProgress: RouteProgress {
        return self.router.routeProgress
    }
    
    public var location: CLLocation? {
        return self.locationManager.location
    }
    
    public var desiredAccuracy: CLLocationAccuracy {
        return self.locationManager.desiredAccuracy
    }
    
    /// :nodoc: This is used internally when the navigation UI is being used
    public var usesDefaultUserInterface: Bool {
        get {
            return eventsManager.usesDefaultUserInterface
        }
        set {
            eventsManager.usesDefaultUserInterface = newValue
        }
    }
}

fileprivate extension EventsManager {
    func incrementDistanceTraveled(by distance: CLLocationDistance) {
       sessionState.totalDistanceCompleted += distance
    }
    func arriveAtWaypoint() {
        sessionState.departureTimestamp = nil
        sessionState.arrivalTimestamp = nil
    }
    func record(locations: [CLLocation]) {
        locations.forEach(sessionState.pastLocations.push(_:))
    }
}

