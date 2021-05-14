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
    case gantry(positions: [RoadObjectPosition], shape: Geometry)

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
    case polygon(entries: [RoadObjectPosition], exits: [RoadObjectPosition], shape: Geometry)

    /**
     Location of an object represented as a polyline.
     - parameter path: Position of a polyline on a road graph.
     - parameter shape: Shape of a polyline.
     */
    case polyline(path: RoadGraph.Path, shape: Geometry)

    /**
     Location of an object represented as an OpenLR line.
     - parameter path: Position of a line on a road graph.
     - parameter shape: Shape of a line.
     */
    case openLRLine(path: RoadGraph.Path, shape: Geometry)

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
    case routeAlert(shape: Geometry)

    init(_ native: MapboxNavigationNative.MBNNMatchedRoadObjectLocation) {
        if native.isMBNNOpenLRLineLocation() {
            let location = native.getMBNNOpenLRLineLocation()
            self = .openLRLine(path: RoadGraph.Path(location.path), shape: Geometry(location.shape))
        } else if native.isMBNNOpenLRPointAlongLineLocation() {
            let location = native.getMBNNOpenLRPointAlongLineLocation()
            self = .openLRPoint(position: RoadGraph.Position(location.position),
                                sideOfRoad: OpenLRSideOfRoad(location.sideOfRoad),
                                orientation: OpenLROrientation(location.orientation),
                                coordinate: location.coordinate)
        } else if native.isMBNNMatchedPolylineLocation() {
            let location = native.getMBNNMatchedPolylineLocation()
            self = .polyline(path: RoadGraph.Path(location.path), shape: Geometry(location.shape))
        } else if native.isMBNNMatchedGantryLocation() {
            let location = native.getMBNNMatchedGantryLocation()
            self = .gantry(positions: location.positions.map(RoadObjectPosition.init), shape: Geometry(location.shape))
        } else if native.isMBNNMatchedPolygonLocation() {
            let location = native.getMBNNMatchedPolygonLocation()
            self = .polygon(entries: location.entries.map(RoadObjectPosition.init),
                            exits: location.exits.map(RoadObjectPosition.init),
                            shape: Geometry(location.shape))
        } else if native.isMBNNMatchedPointLocation() {
            let location = native.getMBNNMatchedPointLocation()
            self = .point(position: RoadObjectPosition(location.position))
        } else if native.isMBNNRouteAlert() {
            let location = native.getMBNNRouteAlert()
            self = .routeAlert(shape: Geometry(location.shape))
        } else {
            preconditionFailure("RoadObjectLocation can't be constructed. Unknown type.")
        }
    }
}
