import Foundation
import MapboxNavigationNative

/**
 The location of a road object in the road graph.
 */
public enum RoadObjectLocation {
    /** Location of a linear object. */
    case path(_ path: RoadGraph.Path)

    /** Location of a point object. */
    case position(_ position: RoadGraph.Position)

    init(_ native: MapboxNavigationNative.RoadObjectLocation) {
        if let path = native.path {
            self = .path(RoadGraph.Path(path))
        } else if let position = native.position {
            self = .position(RoadGraph.Position(position))
        } else {
            preconditionFailure("A road object location must have either a path or a location.")
        }
    }
}
