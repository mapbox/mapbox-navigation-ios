import Foundation
internal import MapboxNavSdkRoadCameras

/// Road camera type.
@_spi(ExperimentalMapboxAPI)
public struct RoadCameraType: RawRepresentable, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// A camera that monitors and enforces speed limits.
    public static let speedCamera = RoadCameraType(
        rawValue: MapboxNavSdkRoadCameras.RoadCameraType.speedCamera
            .rawValue
    )

    /// A camera that checks if a vehicle stops at a red light.
    public static let redLightCamera = RoadCameraType(
        rawValue: MapboxNavSdkRoadCameras.RoadCameraType.redLightCamera
            .rawValue
    )

    /// A combined camera that monitors both speed and red light violations.
    public static let redLightSpeedCamera = RoadCameraType(
        rawValue: MapboxNavSdkRoadCameras.RoadCameraType.redLightSpeedCamera
            .rawValue
    )

    /// A camera that monitors the entry point of a speed control zone.
    public static let speedControlZoneEnter = RoadCameraType(
        rawValue: MapboxNavSdkRoadCameras.RoadCameraType.speedControlZoneEnter
            .rawValue
    )

    /// A camera that monitors the middle point of a speed control zone.
    public static let speedControlZoneMiddle = RoadCameraType(
        rawValue: MapboxNavSdkRoadCameras.RoadCameraType
            .speedControlZoneMiddle.rawValue
    )

    /// A camera that monitors the exit point of a speed control zone.
    public static let speedControlZoneExit = RoadCameraType(
        rawValue: MapboxNavSdkRoadCameras.RoadCameraType.speedControlZoneExit
            .rawValue
    )

    /// A danger zone start, zone around a speed camera.
    public static let dangerZoneEnter = RoadCameraType(
        rawValue: MapboxNavSdkRoadCameras.RoadCameraType.dangerZoneEnter
            .rawValue
    )

    /// A danger zone end, zone around a speed camera.
    public static let dangerZoneExit = RoadCameraType(
        rawValue: MapboxNavSdkRoadCameras.RoadCameraType.dangerZoneExit
            .rawValue
    )

    /// A camera that monitors lane control.
    public static let laneControlCamera = RoadCameraType(
        rawValue: MapboxNavSdkRoadCameras.RoadCameraType.laneControlCamera
            .rawValue
    )

    /// A camera that monitors passage control.
    public static let passageControlCamera = RoadCameraType(
        rawValue: MapboxNavSdkRoadCameras.RoadCameraType.passageControlCamera
            .rawValue
    )
}

extension RoadCameraType {
    init(_ native: MapboxNavSdkRoadCameras.RoadCameraType) {
        self.init(rawValue: native.rawValue)
    }

    var native: MapboxNavSdkRoadCameras.RoadCameraType? {
        MapboxNavSdkRoadCameras.RoadCameraType(rawValue: rawValue)
    }
}
