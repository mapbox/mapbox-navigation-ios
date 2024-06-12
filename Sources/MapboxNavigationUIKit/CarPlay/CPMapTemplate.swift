import CarPlay
import Foundation
import MapboxDirections

extension CLLocationDirection {
    init?(panDirection: CPMapTemplate.PanDirection) {
        var horizontalBias: Double?
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

extension CPTemplate {
    var currentActivity: CarPlayActivity? {
        guard let userInfo = userInfo as? CarPlayUserInfo else { return nil }
        return userInfo[CarPlayManager.currentActivityKey] as? CarPlayActivity
    }
}
