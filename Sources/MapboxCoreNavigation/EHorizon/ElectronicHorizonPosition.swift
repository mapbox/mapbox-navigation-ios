import Foundation
import MapboxNavigationNative

extension ElectronicHorizon {

    /**
     The position on the `ElectornicHorizon`.
     */
    public class Position {

        /** Current graph position */
        public let position: RoadGraph.Position

        /** Tree of edges */
        public let tree: ElectronicHorizon

        /** Result type */
        public let type: ResultType

        init(_ native: ElectronicHorizonPosition) {
            self.position = RoadGraph.Position(try! native.position())
            self.tree = ElectronicHorizon(try! native.tree())
            self.type = ResultType(try! native.type())
        }
    }
}
