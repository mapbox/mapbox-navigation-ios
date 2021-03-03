import CoreGraphics
import Foundation
import MapboxDirections
import MapboxCoreNavigation
import MapboxMaps
import Turf

/**
 The `NavigationMapViewDelegate` provides methods for configuring the NavigationMapView, as well as responding to events triggered by the NavigationMapView.
 */
public protocol NavigationMapViewDelegate: class, UnimplementedLogging {
    /**
     Asks the receiver to return a `CircleLayer` for waypoints, given an identifier and source.
     This method is invoked any time waypoints are added or shown.
     - parameter navigationMapView: The `NavigationMapView`.
     - parameter identifier: The style identifier.
     - parameter source: The Layer source containing the waypoint data that this method would style.
     - returns: A `CircleLayer` that the map applies to all waypoints.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, waypointCircleLayerWithIdentifier identifier: String, sourceIdentifier: String) -> CircleLayer?
    
    /**
     Asks the receiver to return a `SymbolLayer` for waypoint symbols, given an identifier and source.
     This method is invoked any time waypoints are added or shown.
     - parameter navigationMapView: The `NavigationMapView`.
     - parameter identifier: The style identifier.
     - parameter source: The Layer source containing the waypoint data that this method would style.
     - returns: A `SymbolLayer` that the map applies to all waypoint symbols.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, waypointSymbolLayerWithIdentifier identifier: String, sourceIdentifier: String) -> SymbolLayer?

    /**
     Tells the receiver that the user has selected a route by interacting with the map view.
     - parameter navigationMapView: The `NavigationMapView`.
     - parameter route: The route that was selected.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect route: Route)
    
    /**
     Tells the receiver that a waypoint was selected.
     - parameter navigationMapView: The `NavigationMapView`.
     - parameter waypoint: The waypoint that was selected.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect waypoint: Waypoint)
    
    /**
     Asks the receiver to return a `FeatureCollection` that describes the geometry of the waypoint.
     - parameter navigationMapView: The `NavigationMapView`.
     - parameter waypoints: The waypoints to be displayed on the map.
     - returns: Optionally, a `FeatureCollection` that defines the shape of the waypoint, or `nil` to use default behavior.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection?
}

public extension NavigationMapViewDelegate {
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, waypointCircleLayerWithIdentifier identifier: String, sourceIdentifier: String) -> CircleLayer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, waypointSymbolLayerWithIdentifier identifier: String, sourceIdentifier: String) -> SymbolLayer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect route: Route) {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect waypoint: Waypoint) {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapViewUserAnchorPoint(_ navigationMapView: NavigationMapView) -> CGPoint {
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
