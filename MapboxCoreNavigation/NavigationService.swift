import Foundation
import CoreLocation
import MapboxDirections

typealias NavigationServiceDelegate = RouteControllerDelegate & TunnelIntersectionManagerDelegate

@objc(MBNavigationService)
protocol NavigationService: class, CLLocationManagerDelegate {
    var locationSource: NavigationLocationManager { get }
    var router: Router { get }
    var eventsManager: EventsManager { get }
    var delegate: NavigationServiceDelegate? { get set }
}

@objc(MBNavigationService)
class MapboxNavigationService: NSObject, NavigationService {
    var locationSource: NavigationLocationManager
    var directionsService: Directions
    var router: Router
    var eventsManager: EventsManager
    var delegate: NavigationServiceDelegate?
    
    @objc convenience init(route: Route) {
        self.init(route: route, directions: nil, locationSource: nil, eventsManager: nil)
    }
    
    @objc required init(route: Route,
                  directions directionsOverride: Directions? = nil,
                  locationSource locationOverride: NavigationLocationManager? = nil,
                  eventsManager eventsOverride: EventsManager? = nil)
    {
        eventsManager = eventsOverride ?? EventsManager(accessToken: route.accessToken)
        directionsService = directionsOverride ?? Directions.shared
        locationSource = locationOverride ?? NavigationLocationManager()
        router = RouteController(along: route, directions: directionsService, locationManager: locationSource, eventsManager: eventsManager)
        super.init()
        
        locationSource.delegate = self
    }
}

//MARK: - RouteControllerDelegate
extension MapboxNavigationService: RouteControllerDelegate {
    typealias Default = RouteController.DefaultBehavior
    
    //MARK: Messages
    func routeController(_ routeController: RouteController, willRerouteFrom location: CLLocation) {
        delegate?.routeController?(routeController, willRerouteFrom: location)
    }
    func routeController(_ routeController: RouteController, didRerouteAlong route: Route) {
        delegate?.routeController?(routeController, didRerouteAlong: route)
    }
    func routeController(_ routeController: RouteController, didFailToRerouteWith error: Error) {
        delegate?.routeController?(routeController, didFailToRerouteWith: error)
    }
    func routeController(_ routeController: RouteController, didUpdate locations: [CLLocation]) {
        delegate?.routeController?(routeController, didUpdate: locations)
    }
    
    //MARK: Questions
    func routeController(_ routeController: RouteController, shouldRerouteFrom location: CLLocation) -> Bool {
        return delegate?.routeController?(routeController, shouldRerouteFrom: location) ?? Default.shouldRerouteFromLocation
    }
    func routeController(_ routeController: RouteController, shouldDiscard location: CLLocation) -> Bool {
        return delegate?.routeController?(routeController,shouldDiscard: location) ?? Default.shouldDiscardLocation
    }
    func routeController(_ routeController: RouteController, didArriveAt waypoint: Waypoint) -> Bool {
        return delegate?.routeController?(routeController, didArriveAt: waypoint) ?? Default.didArriveAtWaypoint
    }
    func routeController(_ routeController: RouteController, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool {
        return delegate?.routeController?(routeController, shouldPreventReroutesWhenArrivingAt: waypoint) ?? Default.shouldPreventReroutesWhenArrivingAtWaypoint
    }
    func routeControllerShouldDisableBatteryMonitoring(_ routeController: RouteController) -> Bool {
        return delegate?.routeControllerShouldDisableBatteryMonitoring?(routeController) ?? Default.shouldDisableBatteryMonitoring
    }
}

