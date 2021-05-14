import Foundation
import CoreLocation
import MapboxNavigationNative

/**
 * Contains information about distance to the road object of a concrete
 * type/shape (gantry, polygon, line, point etc.).
 */
public enum RoadObjectDistanceInfo {
    /**
     The information about distance to the road object represented as a point.
     */
    case point(PointDistanceInfo)
    
    /**
     The information about distance to the road object represented as a gantry.
     */
    case gantry(GantryDistanceInfo)
    
    /**
     The information about distance to the road object represented as a polygon.
     */
    case polygon(PolygonDistanceInfo)
    
    /**
     The information about distance to the road object represented as a subgraph.
     */
    case subgraph(SubgraphDistanceInfo)
    
    /**
     The information about distance to the road object represented as a line.
     */
    case line(LineDistanceInfo)

    init(_ native: MapboxNavigationNative.MBNNRoadObjectDistanceInfo) {
        if native.isMBNNPointDistanceInfo() {
            self = .point(PointDistanceInfo(native.getMBNNPointDistanceInfo()))
        } else if native.isMBNNGantryDistanceInfo() {
            self = .gantry(GantryDistanceInfo(native.getMBNNGantryDistanceInfo()))
        } else if native.isMBNNPolygonDistanceInfo() {
            self = .polygon(PolygonDistanceInfo(native.getMBNNPolygonDistanceInfo()))
        } else if native.isMBNNSubGraphDistanceInfo() {
            self = .subgraph(SubgraphDistanceInfo(native.getMBNNSubGraphDistanceInfo()))
        } else if native.isMBNNLineDistanceInfo() {
            self = .line(LineDistanceInfo(native.getMBNNLineDistanceInfo()))
        } else {
            preconditionFailure("RoadObjectDistanceInfo can't be constructed. Unknown type.")
        }
    }
}
