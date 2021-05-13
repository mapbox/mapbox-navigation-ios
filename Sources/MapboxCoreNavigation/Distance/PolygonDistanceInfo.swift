import Foundation
import MapboxNavigationNative

/**
 * Contains information about distance to the road object represented as polygon.
 */
public struct PolygonDistanceInfo {

    /** Distance to the nearest entry */
    public let distanceToNearestEntry: CLLocationDistance

    /** Distance to the nearest exit */
    public let distanceToNearestExit: CLLocationDistance

    /** `true` if we're currently inside the object */
    public let isInside: Bool

    /**
     Initializes a new `PolygonDistanceInfo` object.
     
     - parameter distanceToNearestEntry: Distance measured in meters to the nearest entry.
     - parameter distanceToNearestExit: Distance measured in meters to nearest exit.
     - parameter isInside: Boolean to indicate whether we're currently "inside" the object.
     */
    public init(distanceToNearestEntry: CLLocationDistance, distanceToNearestExit: CLLocationDistance, isInside: Bool) {
        self.distanceToNearestEntry = distanceToNearestEntry
        self.distanceToNearestExit = distanceToNearestExit
        self.isInside = isInside
    }

    init(_ native: MapboxNavigationNative.PolygonDistanceInfo) {
        distanceToNearestEntry = native.distanceToNearestEntry
        distanceToNearestExit = native.distanceToNearestExit
        isInside = native.isInside
    }
}
