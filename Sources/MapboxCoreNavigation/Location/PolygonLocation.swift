import Foundation
import MapboxNavigationNative
import Turf

/**
 * Contains information about the location of the road object represented as polygon
 * on the road graph.
 */
public struct PolygonLocation {

    /** Positions of polygon entries */
    public let entries: [RoadObjectPosition]

    /** Positions of polygon exits */
    public let exits: [RoadObjectPosition]

    /** Shape of a polygon */
    public let shape: Geometry

    /**
     Initializes a new `PolygonLocation` object with given positions of polygon entries and exits, and a given shape.
     */
    public init(entries: [RoadObjectPosition], exits: [RoadObjectPosition], shape: Geometry) {
        self.entries = entries
        self.exits = exits
        self.shape = shape
    }

    init(_ native: MapboxNavigationNative.MatchedPolygonLocation) {
        entries = native.entries.map(RoadObjectPosition.init)
        exits = native.exits.map(RoadObjectPosition.init)
        shape = Geometry(native.shape)
    }
}
