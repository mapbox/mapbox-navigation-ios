import Foundation
import MapboxNavigationNative
import MapboxDirections

class NativeRouteController: Routable {
    
    var route: Route
    var locationManager: NavigationLocationManager
    
    required init(route: Route, locationManager: NavigationLocationManager) {
        self.route = route
        self.locationManager = locationManager
    }
    
    func isOnRoute(_ location: CLLocation) -> Bool {
        return false
    }
}
