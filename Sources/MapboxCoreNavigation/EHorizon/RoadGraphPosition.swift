import Foundation
import MapboxNavigationNative

extension RoadGraph {

    /** The position of a point object in the road graph.
     
        - note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the feature.
     */
    public struct Position {

        /** The edge identifier along which the point object lies. */
        public let edgeIdentifier: Edge.Identifier

        /** The distance from the start of an edge to the point object as a fraction of the edge’s length from 0 to 1. */
        public let fractionFromStart: Double

        /**
         Initializes a new `Position` object with a given edge identifier and fraction from the start of the edge.
         */
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

extension GraphPosition {
    convenience init(_ position: RoadGraph.Position) {
        self.init(edgeId: UInt64(position.edgeIdentifier),
                  percentAlong: position.fractionFromStart)
    }
}
