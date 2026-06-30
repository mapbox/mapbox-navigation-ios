import CoreLocation
import Foundation
internal import MapboxNavSdk

/// Information about a speed zone, including entry, middle, and exit cameras.
/// Speed zones represent areas monitored for speed enforcement with cameras at entry, middle, and/or exit points.
@_spi(ExperimentalMapboxAPI)
public struct SpeedZoneInfo: Sendable, Equatable {
    /// Unique identifier for the speed zone.
    public let zoneId: String

    /// The road camera at the entry point of the speed zone.
    public let entry: RoadCamera

    /// Road cameras located between entry and exit points of the speed zone.
    public let middle: [RoadCamera]

    /// The road camera at the exit point of the speed zone.
    public let exit: RoadCamera

    /// The total distance of the speed zone in meters.
    public let zoneLength: CLLocationDistance

    /// The remaining distance to the end of the speed zone in meters, or nil if unknown.
    public let distanceRemaining: CLLocationDistance?

    /// The duration the vehicle has spent in the speed zone in seconds, or nil if not available.
    public let durationInZone: TimeInterval?

    public init(
        zoneId: String,
        entry: RoadCamera,
        middle: [RoadCamera],
        exit: RoadCamera,
        zoneLength: CLLocationDistance,
        distanceRemaining: CLLocationDistance?,
        durationInZone: TimeInterval?
    ) {
        self.zoneId = zoneId
        self.entry = entry
        self.middle = middle
        self.exit = exit
        self.zoneLength = zoneLength
        self.distanceRemaining = distanceRemaining
        self.durationInZone = durationInZone
    }
}

extension SpeedZoneInfo {
    init(_ native: MapboxNavSdk.SpeedZoneInfo) {
        self.init(
            zoneId: native.zoneId,
            entry: RoadCamera(native.entry),
            middle: native.middle.map(RoadCamera.init),
            exit: RoadCamera(native.exit),
            zoneLength: native.zoneLength,
            distanceRemaining: native.distanceRemaining?.doubleValue,
            durationInZone: native.durationInZone?.doubleValue
        )
    }
}
