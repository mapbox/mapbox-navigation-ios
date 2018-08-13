import Foundation
import CoreLocation
import MapboxDirections

@objc public protocol NavigationServiceDelegate: RouterDelegate, TunnelIntersectionManagerDelegate {}
@objc(MBNavigationService)
public protocol NavigationService: class, CLLocationManagerDelegate {
    var locationSource: NavigationLocationManager { get }
    var router: Router { get }
    var route: Route { get set }
    var eventsManager: EventsManager { get }
    weak var delegate: NavigationServiceDelegate? { get set }
    
    func start()
    func stop()
}

@objc(MBNavigationService)
public class MapboxNavigationService: NSObject, NavigationService {
    public var locationSource: NavigationLocationManager
    var directionsService: Directions
    public var router: Router
    public var eventsManager: EventsManager
    public weak var delegate: NavigationServiceDelegate?
    
    @objc convenience init(route: Route) {
        self.init(route: route, directions: nil, locationSource: nil, eventsManager: nil)
    }
    
    @objc required public init(route: Route,
                  directions directionsOverride: Directions? = nil,
                  locationSource locationOverride: NavigationLocationManager? = nil,
                  eventsManager eventsOverride: EventsManager? = nil)
    {
        eventsManager = eventsOverride ?? EventsManager(accessToken: route.accessToken)
        directionsService = directionsOverride ?? Directions.shared
        locationSource = locationOverride ?? NavigationLocationManager()
        locationSource.activityType = route.routeOptions.activityType
        
        router = RouteController(along: route, directions: directionsService, locationManager: locationSource, eventsManager: eventsManager)
        super.init()
        
        router.delegate = self
        locationSource.delegate = self
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
        locationSource.startUpdatingHeading()
        locationSource.startUpdatingLocation()
    }
    
    public func stop() {
        locationSource.stopUpdatingHeading()
        locationSource.stopUpdatingLocation()
    }
    
}

extension MapboxNavigationService: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        router.locationManager?(manager, didUpdateHeading: newHeading)
    }
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        router.locationManager?(manager, didUpdateLocations: locations)
    }
}

//MARK: - RouteControllerDelegate
extension MapboxNavigationService: RouteControllerDelegate {
    typealias Default = RouteController.DefaultBehavior
    
    public func routeController(_ routeController: RouteController, willRerouteFrom location: CLLocation) {
        delegate?.routeController?(routeController, willRerouteFrom: location)
    }
    public func routeController(_ routeController: RouteController, didRerouteAlong route: Route) {
        delegate?.routeController?(routeController, didRerouteAlong: route)
    }
    public func routeController(_ routeController: RouteController, didFailToRerouteWith error: Error) {
        delegate?.routeController?(routeController, didFailToRerouteWith: error)
    }
    public func routeController(_ routeController: RouteController, didUpdate locations: [CLLocation]) {
        delegate?.routeController?(routeController, didUpdate: locations)
    }
    
    //MARK: Questions
    public func routeController(_ routeController: RouteController, shouldRerouteFrom location: CLLocation) -> Bool {
        return delegate?.routeController?(routeController, shouldRerouteFrom: location) ?? Default.shouldRerouteFromLocation
    }
    public func routeController(_ routeController: RouteController, shouldDiscard location: CLLocation) -> Bool {
        return delegate?.routeController?(routeController,shouldDiscard: location) ?? Default.shouldDiscardLocation
    }
    public func routeController(_ routeController: RouteController, didArriveAt waypoint: Waypoint) -> Bool {
        return delegate?.routeController?(routeController, didArriveAt: waypoint) ?? Default.didArriveAtWaypoint
    }
    public func routeController(_ routeController: RouteController, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool {
        return delegate?.routeController?(routeController, shouldPreventReroutesWhenArrivingAt: waypoint) ?? Default.shouldPreventReroutesWhenArrivingAtWaypoint
    }
    public func routeControllerShouldDisableBatteryMonitoring(_ routeController: RouteController) -> Bool {
        return delegate?.routeControllerShouldDisableBatteryMonitoring?(routeController) ?? Default.shouldDisableBatteryMonitoring
    }
}

