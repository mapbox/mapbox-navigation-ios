import Foundation
import MapboxDirections

extension Waypoint {
    var location: CLLocation {
        return CLLocation.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
