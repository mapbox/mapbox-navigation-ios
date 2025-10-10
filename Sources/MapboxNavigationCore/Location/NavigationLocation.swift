import CoreLocation
import Foundation

/// Location information.
public struct NavigationLocation: Sendable, Equatable {
    /// The geographical coordinate information.
    public let coordinate: CLLocationCoordinate2D
    /// The altitude above mean sea level associated with a location, measured in meters.
    public let altitude: CLLocationDistance
    /// The radius of uncertainty for the location, measured in meters.
    public let horizontalAccuracy: CLLocationAccuracy
    /// The validity of the altitude values, and their estimated uncertainty, measured in meters.
    public let verticalAccuracy: CLLocationAccuracy
    /// The direction in which the device is traveling, measured in degrees and relative to due north.
    public let course: CLLocationDirection
    /// The accuracy of the course value, measured in degrees.
    public let courseAccuracy: CLLocationDirectionAccuracy
    /// The instantaneous speed of the device, measured in meters per second.
    public let speed: CLLocationSpeed
    /// The accuracy of the speed value, measured in meters per second.
    public let speedAccuracy: CLLocationSpeedAccuracy
    /// The time at which this location was determined.
    public let timestamp: Date
    /// Information about the source that provides the location.
    public let sourceInfo: NavigationLocationSourceInfo?

    /// Initializes a ``NavigationLocation`` instance.
    /// - Parameters:
    ///   - coordinate: The geographical coordinate information.
    ///   - altitude: The altitude above mean sea level associated with a location, measured in meters.
    ///   - horizontalAccuracy: The radius of uncertainty for the location, measured in meters.
    ///   - verticalAccuracy: The validity of the altitude values, and their estimated uncertainty, measured in meters.
    ///   - course: The direction in which the device is traveling, measured in degrees and relative to due north.
    ///   - courseAccuracy: The accuracy of the course value, measured in degrees.
    ///   - speed: The instantaneous speed of the device, measured in meters per second.
    ///   - speedAccuracy: The accuracy of the speed value, measured in meters per second.
    ///   - timestamp: The time at which this location was determined.
    ///   - sourceInfo: Information about the source that provides the location.
    public init(
        coordinate: CLLocationCoordinate2D,
        altitude: CLLocationDistance,
        horizontalAccuracy: CLLocationAccuracy,
        verticalAccuracy: CLLocationAccuracy,
        course: CLLocationDirection,
        courseAccuracy: CLLocationDirectionAccuracy,
        speed: CLLocationSpeed,
        speedAccuracy: CLLocationSpeedAccuracy,
        timestamp: Date,
        sourceInfo: NavigationLocationSourceInfo? = nil
    ) {
        self.coordinate = coordinate
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.course = course
        self.courseAccuracy = courseAccuracy
        self.speed = speed
        self.speedAccuracy = speedAccuracy
        self.timestamp = timestamp
        self.sourceInfo = sourceInfo
    }
}

extension NavigationLocation {
    init(_ location: CLLocation) {
        self.coordinate = location.coordinate
        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
        self.course = location.course
        self.courseAccuracy = location.courseAccuracy
        self.speed = location.speed
        self.speedAccuracy = location.speedAccuracy
        self.timestamp = location.timestamp
        if #available(iOS 15.0, *) {
            self.sourceInfo = location.sourceInformation.map(NavigationLocationSourceInfo.init)
        } else {
            self.sourceInfo = nil
        }
    }

    var clLocation: CLLocation {
        if #available(iOS 15.0, *) {
            guard let sourceInfo else {
                return clLocationWithoutSourceInfo
            }
            return CLLocation(
                coordinate: coordinate,
                altitude: altitude,
                horizontalAccuracy: horizontalAccuracy,
                verticalAccuracy: verticalAccuracy,
                course: course,
                courseAccuracy: courseAccuracy,
                speed: speed,
                speedAccuracy: speedAccuracy,
                timestamp: timestamp,
                sourceInfo: sourceInfo.clSourceInfo
            )
        }
        return clLocationWithoutSourceInfo
    }

    private var clLocationWithoutSourceInfo: CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            course: course,
            courseAccuracy: courseAccuracy,
            speed: speed,
            speedAccuracy: speedAccuracy,
            timestamp: timestamp
        )
    }
}
