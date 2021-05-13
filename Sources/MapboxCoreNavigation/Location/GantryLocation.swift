import Foundation
import MapboxNavigationNative
import Turf

/**
 * Contains information about the location of the road object represented as gantry
 * on the road graph.
 */
public struct GantryLocation {

    /** Positions of gantry entries */
    public let positions: [RoadObjectPosition]

    /** Shape of a gantry */
    public let shape: Geometry
    
    /**
     Initializes a new `GantryLocation` object with given positions and shape.
     */
    public init(positions: [RoadObjectPosition], shape: Geometry) {
        self.positions = positions
        self.shape = shape
    }

    init(_ native: MapboxNavigationNative.MatchedGantryLocation) {
        positions = native.positions.map(RoadObjectPosition.init)
        shape = Geometry(native.shape)
    }
}
