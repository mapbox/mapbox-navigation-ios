import Foundation
import MapboxNavigationNative
import CoreLocation

extension MBFixLocation {
    
    func asCLLocation() -> CLLocation {
        let timestamp: TimeInterval = time?.doubleValue ?? Date().timeIntervalSince1970
        
        return CLLocation(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lon)),
                          altitude: altitude?.doubleValue ?? 0,
                          horizontalAccuracy: accuracyHorizontal?.doubleValue ?? 0,
                          verticalAccuracy: 0,
                          course: bearing?.doubleValue ?? 0,
                          speed: speed?.doubleValue ?? 0,
                          timestamp: Date(timeIntervalSince1970: timestamp))
    }
}
