import Foundation
import CoreLocation
import MapboxNavigationNative

public struct EHorizonObjectDistanceInfo {

    /** Distance along the road graph from current position to entry point of object in meters, if already "within" object will be equal to zero */
    public let distanceToEntry: CLLocationDistance

    /** Distance along the road graph from current position to end of road object */
    public let distanceToEnd: CLLocationDistance

    /** If we enter road object from it's start, if already "within" object - always false */
    public let isEntryFromStart: Bool

    /** Length of "long" objects */
    public let length: CLLocationDistance?

    /** Type of road object */
    public let type: EHorizonObjectType

    init(_ native: RoadObjectDistanceInfo) {
        self.distanceToEntry = native.distanceToEntry
        self.distanceToEnd = native.distanceToEnd
        self.isEntryFromStart = native.isEntryFromStart
        self.length = native.length as? Double
        self.type = EHorizonObjectType(native.type)
    }
}
