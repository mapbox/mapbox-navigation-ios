import Foundation
import MapboxNavigationNative
import CoreLocation

extension MBFixLocation {
    
    func asCLLocation() -> CLLocation {
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let altitude: CLLocationDistance = self.altitude?.doubleValue ?? 0
        let horizontalAccuracy: CLLocationAccuracy = self.accuracyHorizontal?.doubleValue ?? 0
        let course: CLLocationDirection = self.bearing?.doubleValue ?? 0
        let speed: CLLocationSpeed = self.speed?.doubleValue ?? 0
        let timestamp: TimeInterval = self.time?.doubleValue ?? Date().timeIntervalSince1970
        let date = Date(timeIntervalSince1970: timestamp)
        
        return CLLocation(coordinate: coordinate,
                          altitude: altitude,
                          horizontalAccuracy: horizontalAccuracy,
                          verticalAccuracy: 0,
                          course: course,
                          speed: speed,
                          timestamp: date)
    }
}
