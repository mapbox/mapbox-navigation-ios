import Foundation
import CoreLocation
import MapboxDirections

public protocol Router: class, CLLocationManagerDelegate {
    var route: Route { get }
    func locationIsOnRoute(_ location: CLLocation) -> Bool //userIsOnRoute(_ location: CLLocation)
}
