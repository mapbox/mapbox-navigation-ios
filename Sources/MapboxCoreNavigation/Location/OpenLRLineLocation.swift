import Foundation
import MapboxNavigationNative
import Turf

/**
 * Contains information about the location of the road object represented as
 * OpenLR line on the road graph.
 */
public struct OpenLRLineLocation {
    
    /** Position of a line on a road graph */
    public let path: RoadGraph.Path

    /** Shape of a line */
    public let shape: Geometry

    public init(path: RoadGraph.Path, shape: Geometry) {
        self.path = path
        self.shape = shape
    }

    init(_ native: MapboxNavigationNative.OpenLRLineLocation) {
        path = RoadGraph.Path(native.path)
        shape = Geometry(native.shape)
    }
}
