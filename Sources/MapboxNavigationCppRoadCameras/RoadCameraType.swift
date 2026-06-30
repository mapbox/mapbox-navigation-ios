import Foundation
internal import MapboxNavSdk

/// Road camera type.
@_spi(ExperimentalMapboxAPI)
public struct RoadCameraType: RawRepresentable, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// A camera that monitors and enforces speed limits.
    public static let speedCamera = RoadCameraType(rawValue: MapboxNavSdk.RoadCameraType.speedCamera.rawValue)

    /// A camera that checks if a vehicle stops at a red light.
    public static let redLightCamera = RoadCameraType(rawValue: MapboxNavSdk.RoadCameraType.redLightCamera.rawValue)

    /// A combined camera that monitors both speed and red light violations.
    public static let redLightSpeedCamera = RoadCameraType(
        rawValue: MapboxNavSdk.RoadCameraType.redLightSpeedCamera
            .rawValue
    )

    /// A camera that monitors the entry point of a speed control zone.
    public static let speedControlZoneEnter = RoadCameraType(
        rawValue: MapboxNavSdk.RoadCameraType.speedControlZoneEnter
            .rawValue
    )

    /// A camera that monitors the middle point of a speed control zone.
    public static let speedControlZoneMiddle = RoadCameraType(
        rawValue: MapboxNavSdk.RoadCameraType
            .speedControlZoneMiddle.rawValue
    )

    /// A camera that monitors the exit point of a speed control zone.
    public static let speedControlZoneExit = RoadCameraType(
        rawValue: MapboxNavSdk.RoadCameraType.speedControlZoneExit
            .rawValue
    )

    /// A danger zone start, zone around a speed camera.
    public static let dangerZoneEnter = RoadCameraType(rawValue: MapboxNavSdk.RoadCameraType.dangerZoneEnter.rawValue)

    /// A danger zone end, zone around a speed camera.
    public static let dangerZoneExit = RoadCameraType(rawValue: MapboxNavSdk.RoadCameraType.dangerZoneExit.rawValue)

    /// A camera that monitors lane control.
    public static let laneControlCamera = RoadCameraType(
        rawValue: MapboxNavSdk.RoadCameraType.laneControlCamera
            .rawValue
    )

    /// A camera that monitors passage control.
    public static let passageControlCamera = RoadCameraType(
        rawValue: MapboxNavSdk.RoadCameraType.passageControlCamera
            .rawValue
    )
}

extension RoadCameraType {
    init(_ native: MapboxNavSdk.RoadCameraType) {
        self.init(rawValue: native.rawValue)
    }

    var native: MapboxNavSdk.RoadCameraType? {
        MapboxNavSdk.RoadCameraType(rawValue: rawValue)
    }
}
