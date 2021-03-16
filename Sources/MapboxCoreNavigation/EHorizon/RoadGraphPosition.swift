import Foundation
import MapboxNavigationNative

extension RoadGraph {

    /** The position of a point object in the road graph. */
    public struct Position {

        /** The edge identifier that forms the point object. */
        public let edgeIdentifier: ElectronicHorizon.Edge.Identifier

        /** The distance from the start of the point object to the user’s location as a fraction of the point object’s length from 0 to 1. */
        public let fractionFromStart: Double

        init(_ native: GraphPosition) {
            self.edgeIdentifier = UInt(native.edgeId)
            self.fractionFromStart = native.percentAlong
        }
    }
}
