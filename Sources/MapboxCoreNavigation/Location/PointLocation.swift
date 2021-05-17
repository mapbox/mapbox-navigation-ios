import Foundation
import MapboxNavigationNative

/**
 * Contains information about the location of the road object represented as point
 * on the road graph.
 */
public struct PointLocation {

    /** Position of the object on the road graph */
    public let position: RoadObjectPosition

    public init(position: RoadObjectPosition) {
        self.position = position
    }

    init(_ native: MapboxNavigationNative.MatchedPointLocation) {
        position = RoadObjectPosition(native.position)
    }
}
