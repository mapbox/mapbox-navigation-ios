import Foundation
internal import MapboxNavSdk

/// Configuration for displaying road cameras on the map.
@_spi(ExperimentalMapboxAPI)
public struct RoadCamerasDisplayConfig: Sendable {
    /// The distance (in meters) at which to start showing the road cameras.
    public var startShowDistance: Int32

    /// The distance (in meters) at which to stop showing the road cameras.
    public var stopShowDistance: Int32

    /// The travel time (in seconds) at which to start showing the road cameras.
    public var startShowTravelTime: TimeInterval?

    /// The travel time (in seconds) at which to stop showing the road cameras.
    public var stopShowTravelTime: TimeInterval?

    /// Whether to show speed cameras.
    public var showSpeedCameras: Bool

    /// Whether to show red light cameras.
    public var showRedLightCameras: Bool

    /// Whether to show red light speed cameras.
    public var showRedLightSpeedCameras: Bool

    /// Whether to show speed zone control enter cameras.
    public var showSpeedZoneControlEnter: Bool

    /// Whether to show speed zone control middle cameras.
    public var showSpeedZoneControlMiddle: Bool

    /// Whether to show speed zone control exit cameras.
    public var showSpeedZoneControlExit: Bool

    /// Whether to show danger zone enter cameras.
    public var showDangerZoneEnter: Bool

    /// Whether to show danger zone exit cameras.
    public var showDangerZoneExit: Bool

    /// Whether to show lane control cameras.
    public var showLaneControl: Bool

    /// Whether to show passage control cameras.
    public var showPassageControl: Bool

    /// The interval (in meters) at which to display cameras in the route preview.
    public var previewDisplayInterval: Int32

    public init(
        startShowDistance: Int32 = 1000,
        stopShowDistance: Int32 = 10,
        startShowTravelTime: Double? = nil,
        stopShowTravelTime: Double? = nil,
        showSpeedCameras: Bool = true,
        showRedLightCameras: Bool = true,
        showRedLightSpeedCameras: Bool = true,
        showSpeedZoneControlEnter: Bool = true,
        showSpeedZoneControlMiddle: Bool = true,
        showSpeedZoneControlExit: Bool = true,
        showDangerZoneEnter: Bool = true,
        showDangerZoneExit: Bool = true,
        showLaneControl: Bool = true,
        showPassageControl: Bool = true,
        previewDisplayInterval: Int32 = 1000,
    ) {
        self.startShowDistance = startShowDistance
        self.stopShowDistance = stopShowDistance
        self.startShowTravelTime = startShowTravelTime
        self.stopShowTravelTime = stopShowTravelTime
        self.showSpeedCameras = showSpeedCameras
        self.showRedLightCameras = showRedLightCameras
        self.showRedLightSpeedCameras = showRedLightSpeedCameras
        self.showSpeedZoneControlEnter = showSpeedZoneControlEnter
        self.showSpeedZoneControlMiddle = showSpeedZoneControlMiddle
        self.showSpeedZoneControlExit = showSpeedZoneControlExit
        self.showDangerZoneEnter = showDangerZoneEnter
        self.showDangerZoneExit = showDangerZoneExit
        self.showLaneControl = showLaneControl
        self.showPassageControl = showPassageControl
        self.previewDisplayInterval = previewDisplayInterval
    }
}

extension RoadCamerasDisplayConfig {
    init(_ native: MapboxNavSdk.RoadCamerasDisplayConfig) {
        self.init(
            startShowDistance: native.startShowDistance,
            stopShowDistance: native.stopShowDistance,
            startShowTravelTime: native.startShowTravelTime?.doubleValue,
            stopShowTravelTime: native.stopShowTravelTime?.doubleValue,
            showSpeedCameras: native.showSpeedCameras,
            showRedLightCameras: native.showRedLightCameras,
            showRedLightSpeedCameras: native.showRedLightSpeedCameras,
            showSpeedZoneControlEnter: native.showSpeedZoneControlEnter,
            showSpeedZoneControlMiddle: native.showSpeedZoneControlMiddle,
            showSpeedZoneControlExit: native.showSpeedZoneControlExit,
            showDangerZoneEnter: native.showDangerZoneEnter,
            showDangerZoneExit: native.showDangerZoneExit,
            showLaneControl: native.showLaneControl,
            showPassageControl: native.showPassageControl,
            previewDisplayInterval: native.previewDisplayInterval,
        )
    }

    var native: MapboxNavSdk.RoadCamerasDisplayConfig {
        MapboxNavSdk.RoadCamerasDisplayConfig(
            startShowDistance: startShowDistance,
            stopShowDistance: stopShowDistance,
            startShowTravelTime: startShowTravelTime.map(NSNumber.init(value:)),
            stopShowTravelTime: stopShowTravelTime.map(NSNumber.init(value:)),
            showSpeedCameras: showSpeedCameras,
            showRedLightCameras: showRedLightCameras,
            showRedLightSpeedCameras: showRedLightSpeedCameras,
            showSpeedZoneControlEnter: showSpeedZoneControlEnter,
            showSpeedZoneControlMiddle: showSpeedZoneControlMiddle,
            showSpeedZoneControlExit: showSpeedZoneControlExit,
            showDangerZoneEnter: showDangerZoneEnter,
            showDangerZoneExit: showDangerZoneExit,
            showLaneControl: showLaneControl,
            showPassageControl: showPassageControl,
            showInPreview: false,
            previewDisplayInterval: previewDisplayInterval,
            showInFreeDrive: false
        )
    }
}
