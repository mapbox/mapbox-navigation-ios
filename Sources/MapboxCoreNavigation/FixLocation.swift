import CoreLocation
import Foundation
import MapboxNavigationNative


extension FixLocation {
    convenience init(_ location: CLLocation, isMock: Bool = false) {
        var bearingAccuracy: NSNumber? = nil
        if #available(iOS 13.4, *) {
            bearingAccuracy = location.courseAccuracy >= 0 ? location.courseAccuracy as NSNumber : nil
        }

        var provider: String? = nil
        #if compiler(>=5.5)
        if #available(iOS 15.0, *) {
            if let sourceInformation = location.sourceInformation {
                // in some scenarios we store this information to history files, so to save space there, we use "short" names and 1/0 instead of true/false
                let isSimulated = sourceInformation.isSimulatedBySoftware ? 1 : 0
                let isProducedByAccessory = sourceInformation.isProducedByAccessory ? 1 : 0
                
                provider = "sim:\(isSimulated),acc:\(isProducedByAccessory)"
            }
        }
        #endif
        
        self.init(coordinate: location.coordinate,
                  monotonicTimestampNanoseconds: Int64(location.timestamp.nanosecondsSince1970),
                  time: location.timestamp,
                  speed: location.speed >= 0 ? location.speed as NSNumber : nil,
                  bearing: location.course >= 0 ? location.course as NSNumber : nil,
                  altitude: location.altitude as NSNumber,
                  accuracyHorizontal: location.horizontalAccuracy >= 0 ? location.horizontalAccuracy as NSNumber : nil,
                  provider: provider,
                  bearingAccuracy: bearingAccuracy,
                  speedAccuracy: location.speedAccuracy >= 0 ? location.speedAccuracy as NSNumber : nil,
                  verticalAccuracy: location.verticalAccuracy >= 0 ? location.verticalAccuracy as NSNumber : nil,
                  extras: [:],
                  isMock: isMock)
    }
}
