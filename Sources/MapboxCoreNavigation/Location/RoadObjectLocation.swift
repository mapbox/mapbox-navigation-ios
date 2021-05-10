import Foundation
import MapboxNavigationNative
import Turf

/**
 The location of a road object in the road graph.
 */
public enum RoadObjectLocation {

    /** Location of an object represented as a gantry */
    case gantry(GantryLocation)

    /** Location of an object represented as a point */
    case point(PointLocation)

    /** Location of an object represented as a polygon */
    case polygon(PolygonLocation)

    /** Location of an object represented as a polyline */
    case polyline(PolylineLocation)

    /** Location of an object represented as an OpenLR line */
    case openLRLine(OpenLRLineLocation)

    /** Location of an object represented as an OpenLR point */
    case openLRPoint(OpenLRPointLocation)

    /** Location of a route alert */
    case routeAlert(RouteAlertLocation)

    init(_ native: MapboxNavigationNative.MBNNMatchedRoadObjectLocation) {
        if native.isMBNNOpenLRLineLocation() {
            self = .openLRLine(OpenLRLineLocation(native.getMBNNOpenLRLineLocation()))
        } else if native.isMBNNOpenLRPointAlongLineLocation() {
            self = .openLRPoint(OpenLRPointLocation(native.getMBNNOpenLRPointAlongLineLocation()))
        } else if native.isMBNNMatchedPolylineLocation() {
            self = .polyline(PolylineLocation(native.getMBNNMatchedPolylineLocation()))
        } else if native.isMBNNMatchedGantryLocation() {
            self = .gantry(GantryLocation(native.getMBNNMatchedGantryLocation()))
        } else if native.isMBNNMatchedPolygonLocation() {
            self = .polygon(PolygonLocation(native.getMBNNMatchedPolygonLocation()))
        } else if native.isMBNNMatchedPointLocation() {
            self = .point(PointLocation(native.getMBNNMatchedPointLocation()))
        } else if native.isMBNNRouteAlert() {
            self = .routeAlert(RouteAlertLocation(native.getMBNNRouteAlert()))
        } else {
            preconditionFailure("RoadObjectLocation can't be constructed. Unknown type.")
        }
    }
}
