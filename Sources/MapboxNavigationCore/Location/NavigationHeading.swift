import CoreLocation
import Foundation

/// Represents a vector pointing to magnetic North. See `CLHeading`.
public struct NavigationHeading: Equatable, Sendable {
    /// Represents the direction in degrees, where 0 degrees is true North. The direction is referenced from the top of
    /// the device regardless of device orientation as well as the orientation of the user interface.
    public let trueHeading: CLLocationDirection
    /// Represents the direction in degrees, where 0 degrees is magnetic North. The direction is referenced from the top
    /// of the device regardless of device orientation as well as the orientation of the user interface.
    public let magneticHeading: CLLocationDirection
    /// Represents the maximum deviation of where the magnetic heading may differ from the actual geomagnetic heading in
    /// degrees. A negative value indicates an invalid heading.
    public let accuracy: CLLocationDirection
    /// Returns a timestamp for when the magnetic heading was determined.
    public let timestamp: Date

    /// Initializes a ``NavigationHeading`` instance.
    /// - Parameters:
    ///   - trueHeading: The heading (measured in degrees) relative to true north.
    ///   - magneticHeading: The heading (measured in degrees) relative to magnetic north.
    ///   - accuracy: The maximum deviation (measured in degrees) between the reported heading and the true geomagnetic
    /// heading.
    ///   - timestamp: The time at which this heading was determined.
    public init(
        trueHeading: CLLocationDirection,
        magneticHeading: CLLocationDirection,
        accuracy: CLLocationDirection,
        timestamp: Date
    ) {
        self.trueHeading = trueHeading
        self.magneticHeading = magneticHeading
        self.accuracy = accuracy
        self.timestamp = timestamp
    }
}

extension NavigationHeading {
    /// Initializes a ``NavigationHeading`` instance with a given `CLHeading` instance.
    /// - Parameter heading: The orientation of the user’s device.
    public init(_ heading: CLHeading) {
        self.trueHeading = heading.trueHeading
        self.magneticHeading = heading.magneticHeading
        self.accuracy = heading.headingAccuracy
        self.timestamp = heading.timestamp
    }
}

extension CLHeading {
    var navigationHeading: NavigationHeading {
        NavigationHeading(self)
    }
}
