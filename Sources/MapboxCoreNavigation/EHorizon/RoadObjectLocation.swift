import Foundation
import MapboxNavigationNative
import Turf

/**
 The location of a road object in the road graph.
 */
public enum RoadObjectLocation {

    /**
     Location of an object represented as a gantry.
     - parameter positions: Positions of gantry entries.
     - parameter shape: Shape of a gantry.
     */
    case gantry(positions: [RoadObjectPosition], shape: Turf.Geometry)

    /**
     Location of an object represented as a point.
     - parameter position: Position of the object on the road graph.
     */
    case point(position: RoadObjectPosition)

    /**
     Location of an object represented as a polygon.
     - parameter entries: Positions of polygon entries.
     - parameter exits: Positions of polygon exits.
     - parameter shape: Shape of a polygon.
     */
    case polygon(entries: [RoadObjectPosition], exits: [RoadObjectPosition], shape: Turf.Geometry)

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
    case subgraph(enters: [RoadObjectPosition], exits: [RoadObjectPosition], shape: Turf.Geometry, edges: [RoadGraph.SubgraphEdge.Identifier: RoadGraph.SubgraphEdge])

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
    case openLRPoint(position: RoadGraph.Position, sideOfRoad: OpenLRSideOfRoad, orientation: OpenLROrientation, coordinate: CLLocationCoordinate2D)

    /**
     Location of a route alert.
     - parameter shape: Shape of an object.
     */
    case routeAlert(shape: Turf.Geometry)

    init(_ native: MapboxNavigationNative.MatchedRoadObjectLocation) {
        if native.isOpenLRLineLocation() {
            let location = native.getOpenLRLineLocation()
            self = .openLRLine(path: RoadGraph.Path(location.getPath()), shape: Geometry(location.getShape()))
        } else if native.isOpenLRPointAlongLineLocation() {
            let location = native.getOpenLRPointAlongLineLocation()
            self = .openLRPoint(position: RoadGraph.Position(location.getPosition()),
                                sideOfRoad: OpenLRSideOfRoad(location.getSideOfRoad()),
                                orientation: OpenLROrientation(location.getOrientation()),
                                coordinate: location.getCoordinate())
        } else if native.isMatchedPolylineLocation() {
            let location = native.getMatchedPolylineLocation()
            self = .polyline(path: RoadGraph.Path(location.getPath()), shape: Geometry(location.getShape()))
        } else if native.isMatchedGantryLocation() {
            let location = native.getMatchedGantryLocation()
            self = .gantry(positions: location.getPositions().map(RoadObjectPosition.init), shape: Geometry(location.getShape()))
        } else if native.isMatchedPolygonLocation() {
            let location = native.getMatchedPolygonLocation()
            self = .polygon(entries: location.getEntries().map(RoadObjectPosition.init),
                            exits: location.getExits().map(RoadObjectPosition.init),
                            shape: Geometry(location.getShape()))
        } else if native.isMatchedPointLocation() {
            let location = native.getMatchedPointLocation()
            self = .point(position: RoadObjectPosition(location.getPosition()))
        } else if native.isRouteAlert() {
            let location = native.getRouteAlert()
            self = .routeAlert(shape: Geometry(location.getShape()))
        } else if native.isMatchedSubgraphLocation() {
            let location = native.getMatchedSubgraphLocation()
            let edges = location.getEdges()
                .map { (id, edge) in (UInt(truncating: id), RoadGraph.SubgraphEdge(edge)) }
            self = .subgraph(enters: location.getEnters().map(RoadObjectPosition.init),
                             exits: location.getExits().map(RoadObjectPosition.init),
                             shape: Geometry(location.getShape()),
                             edges: .init(uniqueKeysWithValues: edges))
        } else {
            preconditionFailure("RoadObjectLocation can't be constructed. Unknown type.")
        }
    }
}
