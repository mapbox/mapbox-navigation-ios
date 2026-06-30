import CoreLocation
import Foundation
internal import MapboxNavSdk

/// Active guidance information for a road camera.
@_spi(ExperimentalMapboxAPI)
public struct RoadCameraActiveGuidanceInfo: Sendable, Equatable {
    /// The unique identifier of the route.
    public let routeId: String

    /// The index of the leg in the route.
    public let legIndex: UInt32

    /// The index of the step in the leg.
    public let stepIndex: Int?

    /// The distance along the leg in meters.
    public let distanceAlongLeg: CLLocationDistance

    /// The distance along the route in meters from the last known position.
    public let distanceAlongRoute: CLLocationDistance

    /// The index of the geometry in the route.
    public let geometryIndex: Int?

    /// The intersection camera is located at.
    public let intersection: UInt32?

    public init(
        routeId: String,
        legIndex: UInt32,
        stepIndex: Int?,
        distanceAlongLeg: CLLocationDistance,
        distanceAlongRoute: CLLocationDistance,
        geometryIndex: Int?,
        intersection: UInt32?
    ) {
        self.routeId = routeId
        self.legIndex = legIndex
        self.stepIndex = stepIndex
        self.distanceAlongLeg = distanceAlongLeg
        self.distanceAlongRoute = distanceAlongRoute
        self.geometryIndex = geometryIndex
        self.intersection = intersection
    }
}

extension RoadCameraActiveGuidanceInfo {
    init(_ native: MapboxNavSdk.RoadCameraActiveGuidanceInfo) {
        self.init(
            routeId: native.routeId,
            legIndex: native.legIndex,
            stepIndex: native.stepIndex?.intValue,
            distanceAlongLeg: native.distanceAlongLeg,
            distanceAlongRoute: native.distanceAlongRoute,
            geometryIndex: native.geometryIndex?.intValue,
            intersection: native.intersection?.uint32Value
        )
    }
}
