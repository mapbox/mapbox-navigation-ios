import Foundation
import MapboxNavigationNative

/**
 The location of a road object in the road graph.
 */
public enum EHorizonObjectLocation {
    /** Location of a linear object. */
    case path(_ path: EHorizonGraphPath)
    
    /** Location of a point object. */
    case position(_ position: EHorizonGraphPosition)

    init(_ native: RoadObjectLocation) {
        if let path = native.path {
            self = .path(EHorizonGraphPath(path))
        } else if let position = native.position {
            self = .position(EHorizonGraphPosition(position))
        } else {
            preconditionFailure("A road object location must have either a path or a location.")
        }
    }
}
