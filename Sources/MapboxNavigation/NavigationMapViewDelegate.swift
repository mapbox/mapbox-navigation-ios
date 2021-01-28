import Foundation
import MapboxDirections
import MapboxCoreNavigation

/**
 The `NavigationMapViewDelegate` provides methods for configuring the NavigationMapView, as well as responding to events triggered by the NavigationMapView.
 */
public protocol NavigationMapViewDelegate: class, UnimplementedLogging {

    // TODO: Add delegate methods, which allow to customize main and alternative route lines, waypoints and their shapes.
    
    /**
     Tells the receiver that the user has selected a route by interacting with the map view.
     - parameter mapView: The NavigationMapView.
     - parameter route: The route that was selected.
     */
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route)
    
    /**
     Tells the receiver that a waypoint was selected.
     - parameter mapView: The NavigationMapView.
     - parameter waypoint: The waypoint that was selected.
     */
    func navigationMapView(_ mapView: NavigationMapView, didSelect waypoint: Waypoint)
    
    /**
     Asks the receiver to return a CGPoint to serve as the anchor for the user icon.
     - important: The return value should be returned in the normal UIKit coordinate-space, NOT CoreAnimation's unit coordinate-space.
     - parameter mapView: The NavigationMapView.
     - returns: A CGPoint (in regular coordinate-space) that represents the point on-screen where the user location icon should be drawn.
     */
    func navigationMapViewUserAnchorPoint(_ mapView: NavigationMapView) -> CGPoint
}

public extension NavigationMapViewDelegate {
    
    // TODO: Add logging with warning regarding unimplemented delegate methods, which allow to customize main and alternative route lines, waypoints and their shapes.
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ mapView: NavigationMapView, didSelect waypoint: Waypoint) {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapViewUserAnchorPoint(_ mapView: NavigationMapView) -> CGPoint {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return .zero
    }
}

// MARK: - NavigationMapViewCourseTrackingDelegate methods

/**
 The `NavigationMapViewCourseTrackingDelegate` provides methods for responding to the `NavigationMapView` starting or stopping course tracking.
 */
public protocol NavigationMapViewCourseTrackingDelegate: class, UnimplementedLogging {
    /**
     Tells the receiver that the map is now tracking the user course.
     - seealso: NavigationMapView.tracksUserCourse
     - parameter mapView: The NavigationMapView.
     */
    func navigationMapViewDidStartTrackingCourse(_ mapView: NavigationMapView)
    
    /**
     Tells the receiver that `tracksUserCourse` was set to false, signifying that the map is no longer tracking the user course.
     - seealso: NavigationMapView.tracksUserCourse
     - parameter mapView: The NavigationMapView.
     */
    func navigationMapViewDidStopTrackingCourse(_ mapView: NavigationMapView)
}

public extension NavigationMapViewCourseTrackingDelegate {
    
    func navigationMapViewDidStartTrackingCourse(_ mapView: NavigationMapView) {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
    }
    
    func navigationMapViewDidStopTrackingCourse(_ mapView: NavigationMapView) {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
    }
}
