import Foundation
import MapboxNavigationNative

/**
 * Contains information about distance to the road object represented as gantry.
 */
public struct GantryDistanceInfo {

    /** Distance to the gantry object */
    public let distance: CLLocationDistance

    /**
     Initializes a new `GantryDistanceInfo` object with a given distance to the object.
     */
    public init(distance: CLLocationDistance) {
        self.distance = distance
    }

    init(_ native: MapboxNavigationNative.GantryDistanceInfo) {
        distance = native.distance
    }
}
