import Foundation
import MapboxNavigationNative

/**
 * Contains information about distance to the road object represented as point.
 */
public struct PointDistanceInfo {

    /** Distance distance to the point object */
    public let distance: CLLocationDistance

    public init(distance: CLLocationDistance) {
        self.distance = distance
    }

    init(_ native: MapboxNavigationNative.PointDistanceInfo) {
        distance = native.distance
    }
}
