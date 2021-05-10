import Foundation
import MapboxNavigationNative
import Turf

/**
 * Contains information about the location of the road object represented as
 * polyline on the road graph.
 */
public struct PolylineLocation {
    
    /** Position of a polyline on a road graph */
    public let path: RoadGraph.Path

    /** Shape of a polyline */
    public let shape: Geometry

    public init(path: RoadGraph.Path, shape: Geometry) {
        self.path = path
        self.shape = shape
    }

    init(_ native: MapboxNavigationNative.MatchedPolylineLocation) {
        path = RoadGraph.Path(native.path)
        shape = Geometry(native.shape)
    }
}
