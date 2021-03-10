import Foundation
import MapboxNavigationNative

extension RoadGraph {

    /** Declares position of an object on the map graph */
    public struct Position {

        /** Edge identifier in road graph */
        public let edgeIdentifier: ElectronicHorizon.Edge.Identifier

        /** Percent along edge shape (0-1) */
        public let percentAlong: Double

        init(_ native: GraphPosition) {
            self.edgeIdentifier = UInt(native.edgeId)
            self.percentAlong = native.percentAlong
        }
    }
}
