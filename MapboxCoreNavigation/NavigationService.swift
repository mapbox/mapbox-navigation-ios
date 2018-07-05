import Foundation
import CoreLocation
import MapboxDirections

protocol NavigationService: class {
    var locationManager: CLLocationManager { get }
    var router: Router { get }
    func didUpdate(routeProgress: RouteProgress)
}
