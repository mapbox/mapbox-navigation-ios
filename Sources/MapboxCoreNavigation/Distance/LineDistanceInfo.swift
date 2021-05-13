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

    /** Distance along the road graph from current position to the most likely exit point in meters. */
    public let distanceToExit: CLLocationDistance

    /** Distance along the road graph from current position to end of the most distant exit */
    public let distanceToEnd: CLLocationDistance

    /** If we enter road object from its start, if already "within" object - always false */
    public let isEntryFromStart: Bool

    /** Length of the road object, measured in meters. */
    public let length: Double

    /**
     Initializes a new `LineDistanceInfo` object.
     
     - parameter distanceToEntry: Distance from the current position to entry point measured in meters along the road graph. This value is 0 if already "within" the object.
     - parameter distanceToExit" Distance from the current position to the most likely exit point measured in meters along the road graph.
     - parameter distanceToEnd: Distance from the current position to the most distance exit point measured in meters along the road graph.
     - parameter isEntryFromStart: Boolean that indicates whether we enter the road object from its start. This value is `false` if already "within" the object.
     - parameter length: Length of the road object measured in meters.
     */
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
