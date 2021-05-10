import Foundation
import CoreLocation
import MapboxNavigationNative

/**
 * Contains information about the location of the road object represented as
 * OpenLR point on the road graph.
 */
public struct OpenLRPointLocation {

    /** Position of the point on the graph */
    public let position: RoadGraph.Position

    /** Specifies on which side of road locates the point */
    public let sideOfRoad: OpenLRSideOfRoad

    /** Specifies orientation */
    public let orientation: OpenLROrientation

    /** Map coordinate of the point */
    public let coordinate: CLLocationCoordinate2D

    public init(position: RoadGraph.Position, sideOfRoad: OpenLRSideOfRoad, orientation: OpenLROrientation, coordinate: CLLocationCoordinate2D) {
        self.position = position
        self.sideOfRoad = sideOfRoad
        self.orientation = orientation
        self.coordinate = coordinate
    }

    init(_ native: MapboxNavigationNative.OpenLRPointAlongLineLocation) {
        position = RoadGraph.Position(native.position)
        sideOfRoad = OpenLRSideOfRoad(native.sideOfRoad)
        orientation = OpenLROrientation(native.orientation)
        coordinate = native.coordinate
    }
}


