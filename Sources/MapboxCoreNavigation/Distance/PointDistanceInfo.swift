import Foundation
import MapboxNavigationNative

/**
 * Contains information about distance to the road object represented as point.
 */
public struct PointDistanceInfo {

    /** Distance to the point object, measure in meters. */
    public let distance: CLLocationDistance

    /**
     Initializes a new `PointDistanceInfo` object with a given distance to the object.
     */
    public init(distance: CLLocationDistance) {
        self.distance = distance
    }

    init(_ native: MapboxNavigationNative.PointDistanceInfo) {
        distance = native.distance
    }
}
