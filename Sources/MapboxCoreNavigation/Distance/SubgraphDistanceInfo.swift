import Foundation
import MapboxNavigationNative

/**
 * Contains information about distance to the road object represented as subgraph.
 */
public struct SubgraphDistanceInfo {

    /** Distance to the nearest entry */
    public let distanceToNearestEntry: CLLocationDistance

    /** Distance to the nearest exit */
    public let distanceToNearestExit: CLLocationDistance

    /** `true` if we're currently inside the object */
    public let isInside: Bool

    public init(distanceToNearestEntry: CLLocationDistance, distanceToNearestExit: CLLocationDistance, isInside: Bool) {
        self.distanceToNearestEntry = distanceToNearestEntry
        self.distanceToNearestExit = distanceToNearestExit
        self.isInside = isInside
    }

    init(_ native: MapboxNavigationNative.SubGraphDistanceInfo) {
        distanceToNearestEntry = native.distanceToNearestEntry
        distanceToNearestExit = native.distanceToNearestExit
        isInside = native.isInside
    }
}
