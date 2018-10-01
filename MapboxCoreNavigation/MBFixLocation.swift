import Foundation
import MapboxNavigationNative
import CoreLocation

extension MBFixLocation {
    
    convenience init(_ location: CLLocation) {
        self.init(location: location.coordinate,
                  time: location.timestamp,
                  speed: location.speed as NSNumber,
                  bearing: location.course as NSNumber,
                  altitude: location.altitude as NSNumber,
                  accuracyHorizontal: location.horizontalAccuracy as NSNumber,
                  provider: nil)
    }
}
