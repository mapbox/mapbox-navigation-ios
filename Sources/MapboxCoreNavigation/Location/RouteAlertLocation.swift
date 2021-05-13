import Foundation
import MapboxNavigationNative
import Turf

/**
 * Contains information about the location of the route alert.
 * It will be produced only for objects that are on the current route that we are actively
 * navigating on.
 */
public struct RouteAlertLocation {

    /** Shape of an object */
    public let shape: Geometry

    /**
     Initializes a `RouteAlertLocation` with a given shape.
     */
    public init(shape: Geometry) {
        self.shape = shape
    }

    init(_ native: MapboxNavigationNative.RouteAlertLocation) {
        shape = Geometry.init(native.shape)
    }
}
