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
    
    // Converts the given angle to be numerically close to the anchor angle, allowing it to be interpolated the shorter path around.
    func normalizedAngle(_ anchorAngle: CLLocationDirection) -> CLLocationDirection {
        var angle = self.toRadians().wrap(min: -Double.pi, max: Double.pi)
        if angle == -Double.pi { angle = Double.pi }
        let diff = abs(angle - anchorAngle.toRadians())
        
        if abs(angle - Double.pi * 2 - anchorAngle.toRadians()) < diff {
            angle -= Double.pi * 2
        }
        
        if abs(angle + Double.pi * 2 - anchorAngle.toRadians()) < diff {
            angle += Double.pi * 2
        }
        
        return angle.toDegrees()
    }
}
