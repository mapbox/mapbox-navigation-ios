import Foundation
import CoreLocation
import MapboxDirections

protocol NavigationService: class {
    var locationSource: CLLocationManager { get }
    var router: Router { get }
    func didUpdate(routeProgress: RouteProgress)
}
