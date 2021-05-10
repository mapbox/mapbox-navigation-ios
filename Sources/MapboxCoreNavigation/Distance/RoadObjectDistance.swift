import Foundation
import MapboxNavigationNative

/**
 * Contains information about distances related to a road object.
 */
public struct RoadObjectDistance {
    
    /** Road object identifier */
    public let roadObjectIdentifier: RoadObjectIdentifier

    /** Road object type */
    public let roadObjectType: RoadObjectType

    /** Type of distance with its metadata */
    public let distanceInfo: RoadObjectDistanceInfo

    public init(roadObjectIdentifier: RoadObjectIdentifier, roadObjectType: RoadObjectType, distanceInfo:   RoadObjectDistanceInfo) {
        self.roadObjectIdentifier = roadObjectIdentifier
        self.roadObjectType = roadObjectType
        self.distanceInfo = distanceInfo
    }

    init(_ native: MapboxNavigationNative.RoadObjectDistance) {
        roadObjectIdentifier = native.roadObjectId
        roadObjectType = RoadObjectType(native.type)
        distanceInfo = RoadObjectDistanceInfo(native.distanceInfo)
    }
}
