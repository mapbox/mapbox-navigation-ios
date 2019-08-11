import Foundation
import MapboxNavigationNative
import CoreLocation

extension MBFixLocation {
    
    convenience init(_ location: CLLocation) {
        self.init(coordinate: location.coordinate,
                  time: location.timestamp,
                  speed: location.speed >= 0 ? location.speed as NSNumber : nil,
                  bearing: location.course >= 0 ? location.course as NSNumber : nil,
                  altitude: location.altitude as NSNumber,
                  accuracyHorizontal: location.horizontalAccuracy >= 0 ? location.horizontalAccuracy as NSNumber : nil,
                  provider: nil)
    }
}

extension MBRouteState: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .invalid:
            return "invalid"
        case .initialized:
            return "initialized"
        case .tracking:
            return "tracking"
        case .complete:
            return "complete"
        case .offRoute:
            return "offRoute"
        case .stale:
            return "stale"
        }
    }
}
