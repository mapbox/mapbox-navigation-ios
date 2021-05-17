import Foundation
import CoreLocation
import MapboxNavigationNative

extension RoadGraph {

    /** A position along a linear object in the road graph. */
    public struct Path {
        /** The edge identifiers that fully or partially coincide with the linear object. */
        public let edgeIdentifiers: [Edge.Identifier]

        /** The distance from the start of an edge to the start of the linear object as a fraction of the edge’s length from 0 to 1. */
        public let fractionFromStart: Double

        /** The distance from the end of the linear object to the end of an edge as a fraction of the edge’s length from 0 to 1. */
        public let fractionToEnd: Double
        
        /** Length of a path, measured in meters. */
        public let length: CLLocationDistance

        public init(edgeIdentifiers: [RoadGraph.Edge.Identifier], fractionFromStart: Double, fractionToEnd: Double, length: CLLocationDistance) {
            self.edgeIdentifiers = edgeIdentifiers
            self.fractionFromStart = fractionFromStart
            self.fractionToEnd = fractionToEnd
            self.length = length
        }

        init(_ native: GraphPath) {
            self.edgeIdentifiers = native.edges.map { $0.uintValue }
            self.fractionFromStart = native.percentAlongBegin
            self.fractionToEnd = native.percentAlongEnd
            self.length = native.length
        }
    }
}
