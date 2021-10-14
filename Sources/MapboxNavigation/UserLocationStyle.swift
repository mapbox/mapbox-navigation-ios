import Foundation
import MapboxMaps

/**
 A type that represents a `UIView` that is `CourseUpdatable`.
 */
public typealias UserCourseView = UIView & CourseUpdatable

/**
 The style of the user location indicator in a `NavigationMapView`.
 */
public enum UserLocationStyle {
    /**
     The course view representing the user’s location and course on the map, switching between `UserPuckCourseView` and `UserHaloCourseView` based on the level of location accuracy.
     */
    case courseView(_ view: UserCourseView = UserPuckCourseView(frame: CGRect(origin: .zero, size: 75.0)))
    
    /**
     A 2-dimensional puck from `MapboxMaps`. Optionally provide `Puck2DConfiguration` to configure the puck's appearance.
     */
    case puck2D(configuration: Puck2DConfiguration? = nil)
    
    /**
     A 3-dimensional puck from `MapboxMaps`. It's required to provide a `Puck3DConfiguration` to configure the puck's appearance.
     */
    case puck3D(configuration: Puck3DConfiguration)
}
