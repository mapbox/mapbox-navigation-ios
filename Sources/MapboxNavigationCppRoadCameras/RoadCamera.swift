import CoreLocation
import Foundation
internal import MapboxNavSdk

/// A road camera on the map.
@_spi(ExperimentalMapboxAPI)
public struct RoadCamera: Sendable, Identifiable, Equatable {
    /// The type of the road camera.
    public let type: RoadCameraType

    /// The unique identifier of the road camera.
    public let id: String

    /// The distance to the road camera in meters.
    public let distance: CLLocationDistance?

    /// The geographical location of the road camera.
    public let point: CLLocationCoordinate2D

    /// The speed limit enforced by the road camera in meters per second.
    public let speedLimit: CLLocationSpeed?

    /// The current speed of the vehicle in meters per second.
    public let currentSpeed: CLLocationSpeed?

    /// The accuracy of the current speed measurement in meters per second.
    public let currentSpeedAccuracy: CLLocationSpeedAccuracy?

    /// The road class of the road camera.
    public let roadClass: String?

    /// Whether the road camera is in the route preview.
    public let isInRoutePreview: Bool

    /// Whether the road camera is in free drive.
    public let isInFreeDrive: Bool

    /// Information about the active guidance for the road camera.
    public let activeGuidanceInfo: RoadCameraActiveGuidanceInfo?

    public init(
        type: RoadCameraType,
        id: String,
        distance: CLLocationDistance?,
        point: CLLocationCoordinate2D,
        speedLimit: CLLocationSpeed?,
        currentSpeed: CLLocationSpeed?,
        currentSpeedAccuracy: CLLocationSpeedAccuracy?,
        roadClass: String?,
        isInRoutePreview: Bool,
        isInFreeDrive: Bool,
        activeGuidanceInfo: RoadCameraActiveGuidanceInfo?
    ) {
        self.type = type
        self.id = id
        self.distance = distance
        self.point = point
        self.speedLimit = speedLimit
        self.currentSpeed = currentSpeed
        self.currentSpeedAccuracy = currentSpeedAccuracy
        self.roadClass = roadClass
        self.isInRoutePreview = isInRoutePreview
        self.isInFreeDrive = isInFreeDrive
        self.activeGuidanceInfo = activeGuidanceInfo
    }
}

extension RoadCamera {
    init(_ native: MapboxNavSdk.RoadCamera) {
        self.init(
            type: RoadCameraType(native.type),
            id: native.id,
            distance: native.distance?.doubleValue,
            point: native.point,
            speedLimit: native.speedLimit?.doubleValue,
            currentSpeed: native.currentSpeed?.doubleValue,
            currentSpeedAccuracy: native.currentSpeedAccuracy?.doubleValue,
            roadClass: native.roadClass,
            isInRoutePreview: native.isInRoutePreview,
            isInFreeDrive: native.isInFreeDrive,
            activeGuidanceInfo: native.activeGuidanceInfo.map(RoadCameraActiveGuidanceInfo.init)
        )
    }

    var native: MapboxNavSdk.RoadCamera? {
        guard let nativeType = type.native else {
            return nil
        }

        return MapboxNavSdk.RoadCamera(
            type: nativeType,
            id: id,
            distance: distance.map(NSNumber.init(value:)),
            point: point,
            speedLimit: speedLimit.map(NSNumber.init(value:)),
            currentSpeed: currentSpeed.map(NSNumber.init(value:)),
            currentSpeedAccuracy: currentSpeedAccuracy.map(NSNumber.init(value:)),
            roadClass: roadClass,
            isInRoutePreview: isInRoutePreview,
            isInFreeDrive: isInFreeDrive,
            activeGuidanceInfo: activeGuidanceInfo.map {
                MapboxNavSdk.RoadCameraActiveGuidanceInfo(
                    routeId: $0.routeId,
                    legIndex: $0.legIndex,
                    stepIndex: $0.stepIndex.map(NSNumber.init(value:)),
                    distanceAlongLeg: $0.distanceAlongLeg,
                    distanceAlongRoute: $0.distanceAlongRoute,
                    geometryIndex: $0.geometryIndex.map(NSNumber.init(value:)),
                    intersection: $0.intersection.map(NSNumber.init(value:))
                )
            }
        )
    }
}
