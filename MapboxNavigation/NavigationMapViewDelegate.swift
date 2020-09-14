import Foundation
import MapboxDirections
import MapboxCoreNavigation

/**
 The `NavigationMapViewDelegate` provides methods for configuring the NavigationMapView, as well as responding to events triggered by the NavigationMapView.
 */
public protocol NavigationMapViewDelegate: class, UnimplementedLogging {

    /**
     Asks the receiver to return an MGLStyleLayer for the main route line, given an identifier and source.
     This method is invoked when the map view loads and any time routes are added.
     - parameter mapView: The NavigationMapView.
     - parameter identifier: The style identifier.
     - parameter source: The source containing the route data that this method would style.
     - returns: An MGLStyleLayer that is applied to the main route line.
    */
    func navigationMapView(_ mapView: NavigationMapView, mainRouteStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?

    /**
     Asks the receiver to return an MGLStyleLayer for the casing layer that surrounds main route line, given an identifier and source.
     This method is invoked when the map view loads and any time routes are added.
     - parameter mapView: The NavigationMapView.
     - parameter identifier: The style identifier.
     - parameter source: The source containing the route data that this method would style.
     - returns: An MGLStyleLayer that is applied as a casing around the main route line.
    */
    func navigationMapView(_ mapView: NavigationMapView, mainRouteCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?

    /**
     Asks the receiver to return an MGLStyleLayer for the alternative route lines, given an identifier and source.
     This method is invoked when the map view loads and any time routes are added.
     - parameter mapView: The NavigationMapView.
     - parameter identifier: The style identifier.
     - parameter source: The source containing the route data that this method would style.
     - returns: An MGLStyleLayer that is applied to alternative routes.
    */
    func navigationMapView(_ mapView: NavigationMapView, alternativeRouteStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?

    /**
     Asks the receiver to return an MGLStyleLayer for the casing layer that surrounds alternative route lines, given an identifier and source.
     This method is invoked when the map view loads and any time routes are added.
     - parameter mapView: The NavigationMapView.
     - parameter identifier: The style identifier.
     - parameter source: The source containing the route data that this method would style.
     - returns: An MGLStyleLayer that is applied as a casing around alternative route lines.
    */
    func navigationMapView(_ mapView: NavigationMapView, alternativeRouteCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Asks the receiver to return an MGLStyleLayer for waypoints, given an identifier and source.
     This method is invoked when the map view loads and any time waypoints are added.
     - parameter mapView: The NavigationMapView.
     - parameter identifier: The style identifier.
     - parameter source: The Layer source containing the waypoint data that this method would style.
     - returns: An MGLStyleLayer that the map applies to all waypoints.
     */
    func navigationMapView(_ mapView: NavigationMapView, waypointStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Asks the receiver to return an MGLStyleLayer for waypoint symbols, given an identifier and source.
     This method is invoked when the map view loads and any time waypoints are added.
     - parameter mapView: The NavigationMapView.
     - parameter identifier: The style identifier.
     - parameter source: The Layer source containing the waypoint data that this method would style.
     - returns: An MGLStyleLayer that the map applies to all waypoint symbols.
     */
    func navigationMapView(_ mapView: NavigationMapView, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
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
     Asks the receiver to return an MGLShape that describes the geometry of the route.
        
     Resulting `MGLShape` will then be styled using `NavigationMapView.navigationMapView(_: mainRouteStyleLayerWithIdentifier: source:)` provided style or a default congestion style if above delegate method was not implemented. In latter case, consider modifing your custom `MGLShape` `attributes` to have 'isAlternateRoute' key set to 'false'. Otherwise style predicate condition will filter out the shape.
     - note: The returned value represents the route in full detail. For example, individual `MGLPolyline` objects in an `MGLShapeCollectionFeature` object can represent traffic congestion segments. For improved performance, you should also implement `navigationMapView(_:simplifiedShapeFor:)`, which defines the overall route as a single feature.
     - parameter mapView: The NavigationMapView.
     - parameter routes: The routes that the sender is asking about. The first route will always be rendered as the main route, while all subsequent routes will be rendered as alternative routes.
     - returns: Optionally, a `MGLShape` that defines the shape of the route, or `nil` to use default behavior.
     */
    func navigationMapView(_ mapView: NavigationMapView, shapeFor routes: [Route]) -> MGLShape?
    
    /**
     Asks the receiver to return an MGLShape that describes the geometry of the route at lower zoomlevels.
     
     Resulting `MGLShape` will then be styled using `NavigationMapView.navigationMapView(_: mainRouteCasingStyleLayerWithIdentifier: source:)` provided style or a default style if above delegate method was not implemented. In latter case, consider modifing your custom `MGLShape` `attributes` to have 'isAlternateRoute' key set to 'false'. Otherwise style predicate condition will filter out the shape.
     - note: The returned value represents the simplfied route. It is designed to be used with `navigationMapView(_:shapeFor:), and if used without its parent method, can cause unexpected behavior.
     - parameter mapView: The NavigationMapView.
     - parameter route: The route that the sender is asking about.
     - returns: Optionally, a `MGLShape` that defines the shape of the route at lower zoomlevels, or `nil` to use default behavior.
     */
    func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeFor route: Route) -> MGLShape?
    
    /**
     Asks the receiver to return an MGLShape that describes the geometry of the waypoint.
     - parameter mapView: The NavigationMapView.
     - parameter waypoints: The waypoints to be displayed on the map.
     - returns: Optionally, a `MGLShape` that defines the shape of the waypoint, or `nil` to use default behavior.
     */
    func navigationMapView(_ mapView: NavigationMapView, shapeFor waypoints: [Waypoint], legIndex: Int) -> MGLShape?
    
    /**
     Asks the receiver to return a CGPoint to serve as the anchor for the user icon.
     - important: The return value should be returned in the normal UIKit coordinate-space, NOT CoreAnimation's unit coordinate-space.
     - parameter mapView: The NavigationMapView.
     - returns: A CGPoint (in regular coordinate-space) that represents the point on-screen where the user location icon should be drawn.
     */
    func navigationMapViewUserAnchorPoint(_ mapView: NavigationMapView) -> CGPoint
    
}

public extension NavigationMapViewDelegate {

    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ mapView: NavigationMapView, mainRouteStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }

    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ mapView: NavigationMapView, mainRouteCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }

    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ mapView: NavigationMapView, alternativeRouteStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }

    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ mapView: NavigationMapView, alternativeRouteCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ mapView: NavigationMapView, waypointStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ mapView: NavigationMapView, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }
    
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
    func navigationMapView(_ mapView: NavigationMapView, shapeFor routes: [Route]) -> MGLShape? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeFor route: Route) -> MGLShape? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ mapView: NavigationMapView, shapeFor waypoints: [Waypoint], legIndex: Int) -> MGLShape? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapViewUserAnchorPoint(_ mapView: NavigationMapView) -> CGPoint {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return .zero
    }
}

// MARK: NavigationMapViewCourseTrackingDelegate
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
