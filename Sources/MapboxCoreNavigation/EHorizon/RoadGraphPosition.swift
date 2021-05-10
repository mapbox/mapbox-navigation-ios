import Foundation
import MapboxNavigationNative

extension RoadGraph {

    /** The position of a point object in the road graph. */
    public struct Position {

        /** The edge identifier along which the point object lies. */
        public let edgeIdentifier: Edge.Identifier

        /** The distance from the start of an edge to the point object as a fraction of the edge’s length from 0 to 1. */
        public let fractionFromStart: Double

        public init(edgeIdentifier: RoadGraph.Edge.Identifier, fractionFromStart: Double) {
            self.edgeIdentifier = edgeIdentifier
            self.fractionFromStart = fractionFromStart
        }

        init(_ native: GraphPosition) {
            self.edgeIdentifier = UInt(native.edgeId)
            self.fractionFromStart = native.percentAlong
        }
    }
}
