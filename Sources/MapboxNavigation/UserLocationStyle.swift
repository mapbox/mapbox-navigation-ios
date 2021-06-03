import Foundation
import MapboxMaps

/**
 The style of user location indicator in a navigation map view.
 */
public enum UserLocationStyle {
    /**
     The default view representing the user’s location and course on the map, switching between `UserPuckCourseView` and `UserHaloCourseView` based on the level of location accuracy.
     */
    case `default`
    
    /**
     A 2-dimensional puck from `MapboxMaps`. Optionally provide `Puck2DConfiguration` to configure the puck's appearance.
     */
    case puck2D(configuration: Puck2DConfiguration)
    
    /**
     A 3-dimensional puck from `MapboxMaps`. It's required to provide a `Puck3DConfiguration` to configure the puck's appearance.
     */
    case puck3D(configuration: Puck3DConfiguration)
}
