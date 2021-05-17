import Foundation
import MapboxNavigationNative

/**
 * Contains information about distance to the road object represented as line.
 */
public struct LineDistanceInfo {

    /**
     * Distance along the road graph from current position to entry point of object in meters,
     * if already "within" object will be equal to zero
     */
    public let distanceToEntry: CLLocationDistance

    /** Distance along the road graph from current position to exit point of object in meters. */
    public let distanceToExit: CLLocationDistance

    /** Distance along the road graph from current position to end of road object */
    public let distanceToEnd: CLLocationDistance

    /** If we enter road object from it's start, if already "within" object - always false */
    public let isEntryFromStart: Bool

    /** Length of "long" objects */
    public let length: Double

    public init(distanceToEntry: CLLocationDistance, distanceToExit: CLLocationDistance, distanceToEnd: CLLocationDistance, isEntryFromStart: Bool, length: Double) {
        self.distanceToEntry = distanceToEntry
        self.distanceToExit = distanceToExit
        self.distanceToEnd = distanceToEnd
        self.isEntryFromStart = isEntryFromStart
        self.length = length
    }

    init(_ native: MapboxNavigationNative.LineDistanceInfo) {
        distanceToEntry = native.distanceToEntry
        distanceToExit = native.distanceToExit
        distanceToEnd = native.distanceToEnd
        isEntryFromStart = native.isEntryFromStart
        length = native.length
    }
}
