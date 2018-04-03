import Foundation
import CoreLocation

extension CLLocationDirection {
    func clockwiseDifference(from otherDirection: CLLocationDirection) -> CLLocationDirection {
        let inAngle = toRadians()
        let outAngle = otherDirection.toRadians()
        let inX = sin(inAngle)
        let inY = cos(inAngle)
        let outX = sin(outAngle)
        let outY = cos(outAngle)
        
        return acos((inX * outX + inY * outY) / 1.0) * (180 / .pi)
    }
    
    var isQualified: Bool {
        return self > -1
    }
}
