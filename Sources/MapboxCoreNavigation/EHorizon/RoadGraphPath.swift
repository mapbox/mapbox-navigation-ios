import Foundation
import CoreLocation
import MapboxNavigationNative

extension RoadGraph {

    /** A position along a linear object in the road graph. */
    public struct Path {
        /** The edge identifiers that form the linear object. */
        public let edgeIdentifiers: [ElectronicHorizon.Edge.Identifier]

        /** The distance from the start of the linear object to the user’s location as a fraction of the linear object’s length from 0 to 1. */
        public let fractionFromStart: Double

        /** The distance from the the user’s location to the end of the linear object as a fraction of the linear object’s length from 0 to 1. */
        public let fractionToEnd: Double
        
        /** Length of a path, measured in meters. */
        public let length: CLLocationDistance

        init(_ native: GraphPath) {
            self.edgeIdentifiers = native.edges.map { $0.uintValue }
            self.fractionFromStart = native.percentAlongBegin
            self.fractionToEnd = native.percentAlongEnd
            self.length = native.length
        }
    }
}
