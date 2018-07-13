import Foundation
import CoreLocation
import MapboxDirections

protocol NavigationService: class {
    var locationSource: CLLocationManager { get }
    var router: Router { get }
    var eventManager: EventsManager { get }
    
    func didUpdate(routeProgress: RouteProgress)
}
