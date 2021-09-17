import Foundation
import MapboxNavigationNative
import Turf

extension RoadObject {
    
    /**
     The location of a road object in the road graph.
     */
    public enum Location {
        
        /**
         Location of an object represented as a gantry.
         - parameter positions: Positions of gantry entries.
         - parameter shape: Shape of a gantry.
         */
        case gantry(positions: [RoadObject.Position], shape: Turf.Geometry)
        
        /**
         Location of an object represented as a point.
         - parameter position: Position of the object on the road graph.
         */
        case point(position: RoadObject.Position)
        
        /**
         Location of an object represented as a polygon.
         - parameter entries: Positions of polygon entries.
         - parameter exits: Positions of polygon exits.
         - parameter shape: Shape of a polygon.
         */
        case polygon(entries: [RoadObject.Position],
                     exits: [RoadObject.Position],
                     shape: Turf.Geometry)
        
        /**
         Location of an object represented as a polyline.
         - parameter path: Position of a polyline on a road graph.
         - parameter shape: Shape of a polyline.
         */
        case polyline(path: RoadGraph.Path, shape: Turf.Geometry)
        
        /**
         Location of an object represented as a subgraph.
         - parameter enters: Positions of the subgraph enters.
         - parameter exits: Positions of the subgraph exits.
         - parameter shape: Shape of a subgraph.
         - parameter edges: Edges of the subgraph associated by id.
         */
        case subgraph(enters: [RoadObject.Position],
                      exits: [RoadObject.Position],
                      shape: Turf.Geometry,
                      edges: [RoadGraph.SubgraphEdge.Identifier: RoadGraph.SubgraphEdge])
        
        /**
         Location of an object represented as an OpenLR line.
         - parameter path: Position of a line on a road graph.
         - parameter shape: Shape of a line.
         */
        case openLRLine(path: RoadGraph.Path, shape: Turf.Geometry)
        
        /**
         Location of an object represented as an OpenLR point.
         - parameter position: Position of the point on the graph.
         - parameter sideOfRoad: Specifies on which side of road the point is located.
         - parameter orientation: Specifies orientation of the object relative to referenced line.
         - parameter coordinate: Map coordinate of the point.
         */
        case openLRPoint(position: RoadGraph.Position,
                         sideOfRoad: OpenLRSideOfRoad,
                         orientation: OpenLROrientation,
                         coordinate: CLLocationCoordinate2D)
        
        /**
         Location of a route alert.
         - parameter shape: Shape of an object.
         */
        case routeAlert(shape: Turf.Geometry)
        
        init(_ native: MapboxNavigationNative.MatchedRoadObjectLocation) {
            switch native.type {
            case .openLRLineLocation:
                let location = native.getOpenLRLineLocation()
                self = .openLRLine(path: RoadGraph.Path(location.getPath()),
                                   shape: Geometry(location.getShape()))
            case .openLRPointAlongLineLocation:
                let location = native.getOpenLRPointAlongLineLocation()
                self = .openLRPoint(position: RoadGraph.Position(location.getPosition()),
                                    sideOfRoad: OpenLRSideOfRoad(location.getSideOfRoad()),
                                    orientation: OpenLROrientation(location.getOrientation()),
                                    coordinate: location.getCoordinate())
            case .matchedPolylineLocation:
                let location = native.getMatchedPolylineLocation()
                self = .polyline(path: RoadGraph.Path(location.getPath()),
                                 shape: Geometry(location.getShape()))
            case .matchedGantryLocation:
                let location = native.getMatchedGantryLocation()
                self = .gantry(positions: location.getPositions().map(RoadObject.Position.init),
                               shape: Geometry(location.getShape()))
            case .matchedPolygonLocation:
                let location = native.getMatchedPolygonLocation()
                self = .polygon(entries: location.getEntries().map(RoadObject.Position.init),
                                exits: location.getExits().map(RoadObject.Position.init),
                                shape: Geometry(location.getShape()))
            case .matchedPointLocation:
                let location = native.getMatchedPointLocation()
                self = .point(position: RoadObject.Position(location.getPosition()))
            case .matchedSubgraphLocation:
                let location = native.getMatchedSubgraphLocation()
                let edges = location.getEdges()
                    .map { (id, edge) in (UInt(truncating: id), RoadGraph.SubgraphEdge(edge)) }
                self = .subgraph(enters: location.getEnters().map(RoadObject.Position.init),
                                 exits: location.getExits().map(RoadObject.Position.init),
                                 shape: Geometry(location.getShape()),
                                 edges: .init(uniqueKeysWithValues: edges))
            case .routeAlertLocation:
                let routeAlertLocation = native.getRouteAlert()
                self = .routeAlert(shape: Geometry(routeAlertLocation.getShape()))
            @unknown default:
                preconditionFailure("RoadObjectLocation can't be constructed. Unknown type.")
            }
        }
    }
}
