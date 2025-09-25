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
    private var carPlayUserInfo: CarPlayUserInfo {
        guard let dictionary = userInfo as? CarPlayUserInfo else {
            let dictionary = CarPlayUserInfo()
            userInfo = dictionary
            return dictionary
        }
        return dictionary
    }

    var currentActivity: CarPlayActivity? {
        get {
            guard let userInfo = userInfo as? CarPlayUserInfo else { return nil }
            return userInfo[CarPlayManager.currentActivityKey] as? CarPlayActivity
        }
        set {
            previousActivity = currentActivity
            var newUserInfo = carPlayUserInfo
            newUserInfo[CarPlayManager.currentActivityKey] = newValue
            userInfo = newUserInfo
        }
    }

    private(set) var previousActivity: CarPlayActivity? {
        get {
            guard let userInfo = userInfo as? CarPlayUserInfo else { return nil }
            return userInfo[CarPlayManager.previousActivityKey] as? CarPlayActivity
        }
        set {
            var newUserInfo = carPlayUserInfo
            newUserInfo[CarPlayManager.previousActivityKey] = newValue
            userInfo = newUserInfo
        }
    }
}
