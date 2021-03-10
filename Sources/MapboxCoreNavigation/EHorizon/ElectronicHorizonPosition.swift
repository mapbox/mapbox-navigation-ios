import Foundation
import MapboxNavigationNative

extension ElectronicHorizon {
    public class Position {

        public let position: RoadGraph.Position

        public let tree: ElectronicHorizon

        public let type: ResultType

        init(_ native: ElectronicHorizonPosition) {
            self.position = RoadGraph.Position(try! native.position())
            self.tree = ElectronicHorizon(try! native.tree())
            self.type = ResultType(try! native.type())
        }
    }
}
