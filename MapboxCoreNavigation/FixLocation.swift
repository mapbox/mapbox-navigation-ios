import CoreLocation
import Foundation
import MapboxNavigationNative

extension FixLocation {
    convenience init(_ location: CLLocation) {
        self.init(coordinate: location.coordinate,
                  time: location.timestamp,
                  speed: location.speed >= 0 ? location.speed as NSNumber : nil,
                  bearing: location.course >= 0 ? location.course as NSNumber : nil,
                  altitude: location.altitude as NSNumber,
                  accuracyHorizontal: location.horizontalAccuracy >= 0 ? location.horizontalAccuracy as NSNumber : nil,
                  provider: nil,
                  bearingAccuracy: nil,
                  speedAccuracy: location.speedAccuracy >= 0 ? location.speedAccuracy as NSNumber : nil,
                  verticalAccuracy: location.verticalAccuracy >= 0 ? location.speedAccuracy as NSNumber : nil)
    }
}
