import Foundation
import CoreLocation
import MapboxNavigationNative

/**
 * Contains information about distance to the road object of a concrete
 * type/shape (gantry, polygon, line, point etc.).
 */
public enum RoadObjectDistanceInfo {
    case point(PointDistanceInfo)
    case gantry(GantryDistanceInfo)
    case polygone(PolygonDistanceInfo)
    case subgraph(SubgraphDistanceInfo)
    case line(LineDistanceInfo)

    init(_ native: MapboxNavigationNative.MBNNRoadObjectDistanceInfo) {
        if native.isMBNNPointDistanceInfo() {
            self = .point(PointDistanceInfo(native.getMBNNPointDistanceInfo()))
        } else if native.isMBNNGantryDistanceInfo() {
            self = .gantry(GantryDistanceInfo(native.getMBNNGantryDistanceInfo()))
        } else if native.isMBNNPolygonDistanceInfo() {
            self = .polygone(PolygonDistanceInfo(native.getMBNNPolygonDistanceInfo()))
        } else if native.isMBNNSubGraphDistanceInfo() {
            self = .subgraph(SubgraphDistanceInfo(native.getMBNNSubGraphDistanceInfo()))
        } else if native.isMBNNLineDistanceInfo() {
            self = .line(LineDistanceInfo(native.getMBNNLineDistanceInfo()))
        } else {
            preconditionFailure("RoadObjectDistanceInfo can't be constructed. Unknown type.")
        }
    }
}
