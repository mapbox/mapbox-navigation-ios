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
        #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(watchOS) || os(tvOS))
            return true
        #else
            return self > -1
        #endif
    }
}
