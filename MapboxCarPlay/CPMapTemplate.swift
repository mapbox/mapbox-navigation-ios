import Foundation
import MapboxDirections
import CarPlay

@available(iOS 12.0, *)
extension CLLocationDirection {
    init?(panDirection: CPMapTemplate.PanDirection) {
        var horizontalBias: Double? = nil
        if panDirection.contains(.right) {
            horizontalBias = 90
        } else if panDirection.contains(.left) {
            horizontalBias = -90
        }
        
        var heading: CLLocationDirection
        if panDirection.contains(.up) {
            heading = 0
            if let horizontalHeading = horizontalBias {
                heading += horizontalHeading / 2
            }
        } else if panDirection.contains(.down) {
            heading = 180
            if let horizontalHeading = horizontalBias {
                heading -= horizontalHeading / 2
            }
        } else if let horizontalHeading = horizontalBias {
            heading = horizontalHeading
        } else {
            return nil
        }
        self = heading.wrap(min: 0, max: 360)
    }
}

