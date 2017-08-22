import Foundation
import CoreLocation

extension CLHeading {
    var preferredHeading: CLLocationDirection {
        guard trueHeading >= 0 || headingAccuracy > 45 else {
            return magneticHeading
        }
        return trueHeading
    }
}
