import Foundation
import MapboxNavigationNative
import CoreLocation

extension MBFixLocation {
    
    func asCLLocation() -> CLLocation {
        return CLLocation(coordinate: location,
                          altitude: altitude?.doubleValue ?? 0,
                          horizontalAccuracy: accuracyHorizontal?.doubleValue ?? 0,
                          verticalAccuracy: 0,
                          course: bearing?.doubleValue ?? 0,
                          speed: speed?.doubleValue ?? 0,
                          timestamp: time)
    }
}
