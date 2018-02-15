import Foundation
import CoreLocation

extension CLLocationDirection {
    func clockwiseDifference(from toDirection: CLLocationDirection) -> CLLocationDirection {
        let inAngle = toRadians()
        let outAngle = toDirection.toRadians()
        let inX = sin(inAngle)
        let inY = cos(inAngle)
        let outX = sin(outAngle)
        let outY = cos(outAngle)
        
        return acos((inX * outX + inY * outY) / 1.0) * (180 / .pi)
    }
}
