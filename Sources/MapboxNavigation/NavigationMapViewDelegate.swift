import CoreGraphics
import Foundation
import MapboxDirections
import MapboxCoreNavigation
import MapboxMaps
import Turf

/**
 The `NavigationMapViewDelegate` provides methods for configuring the `NavigationMapView`, as well as responding to events triggered by the `NavigationMapView`.
 */
public protocol NavigationMapViewDelegate: AnyObject, UnimplementedLogging {
    
    // MARK: Supplying Route Line(s) Data
    
    /**
     Asks the receiver to return a `LineLayer` for the route line, given a layer identifier and a source identifier.
     This method is invoked when the map view loads and any time routes are added.
     
     - parameter navigationMapView: The `NavigationMapView` object.
     - parameter identifier: The `LineLayer` identifier.
     - parameter sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
     - returns: A `LineLayer` that is applied to the route line.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, routeLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer?
    
    /**
     Asks the receiver to return a `LineLayer` for the casing layer that surrounds route line, given a layer identifier and a source identifier.
     This method is invoked when the map view loads and any time routes are added.
     
     - parameter navigationMapView: The `NavigationMapView` object.
     - parameter identifier: The `LineLayer` identifier.
     - parameter sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
     - returns: A `LineLayer` that is applied as a casing around the route line.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, routeCasingLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer?
    
    /**
     Asks the receiver to return a `LineLayer` for highlighting restricted areas portions of the route, given a layer identifier and a source identifier.
     This method is invoked when `showsRestrictedAreasOnRoute` is enabled, the map view loads and any time routes are added.
     
     - parameter navigationMapView: The `NavigationMapView` object.
     - parameter identifier: The `LineLayer` identifier.
     - parameter sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
     - returns: A `LineLayer` that is applied as restricted areas on the route line.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, routeRestrictedAreasLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer?
    
    /**
     Asks the receiver to return an `LineString` that describes the geometry of the route.
     Resulting `LineString` will then be styled using `NavigationMapView.navigationMapView(_:routeLineLayerWithIdentifier:sourceIdentifier:)` provided style or a default congestion style if above delegate method was not implemented.
     
     - parameter navigationMapView: The `NavigationMapView`.
     - parameter route: The route that the sender is asking about.
     - returns: A `LineString` object that defines the shape of the route, or `nil` in case of default behavior.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, shapeFor route: Route) -> LineString?
    
    /**
     Asks the receiver to return an `LineString` that describes the geometry of the route casing.
     Resulting `LineString` will then be styled using `NavigationMapView.navigationMapView(_:routeCasingLineLayerWithIdentifier:sourceIdentifier:)` provided style or a default style if above delegate method was not implemented.
     
     - parameter navigationMapView: The `NavigationMapView`.
     - parameter route: The route that the sender is asking about.
     - returns: A `LineString` object that defines the shape of the route casing, or `nil` in case of default behavior.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, casingShapeFor route: Route) -> LineString?
    
    /**
     Asks the receiver to return an `LineString` that describes the geometry of the route restricted areas.
     Resulting `LineString` will then be styled using `NavigationMapView.navigationMapView(_:routeRestrictedAreasLineLayerWithIdentifier:sourceIdentifier:)` provided style or a default style if above delegate method was not implemented.
     
     - parameter navigationMapView: The `NavigationMapView`.
     - parameter route: The route that the sender is asking about.
     - returns: A `LineString` object that defines the shape of the route restricted areas, or `nil` in case of default behavior.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, restrictedAreasShapeFor route: Route) -> LineString?
    
    // MARK: Supplying Waypoint(s) Data
    
    /**
     Asks the receiver to return a `CircleLayer` for waypoints, given an identifier and source.
     This method is invoked any time waypoints are added or shown.
     
     - parameter navigationMapView: The `NavigationMapView` object.
     - parameter identifier: The `CircleLayer` identifier.
     - parameter sourceIdentifier: Identifier of the source, which contains the waypoint data that this method would style.
     - returns: A `CircleLayer` that the map applies to all waypoints.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, waypointCircleLayerWithIdentifier identifier: String, sourceIdentifier: String) -> CircleLayer?
    
    /**
     Asks the receiver to return a `SymbolLayer` for waypoint symbols, given an identifier and source.
     This method is invoked any time waypoints are added or shown.
     
     - parameter navigationMapView: The `NavigationMapView` object.
     - parameter identifier: The `SymbolLayer` identifier.
     - parameter sourceIdentifier: Identifier of the source, which contains the waypoint data that this method would style.
     - returns: A `SymbolLayer` that the map applies to all waypoint symbols.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, waypointSymbolLayerWithIdentifier identifier: String, sourceIdentifier: String) -> SymbolLayer?
    
    /**
     Asks the receiver to return a `FeatureCollection` that describes the geometry of the waypoint.
     
     - parameter navigationMapView: The `NavigationMapView`.
     - parameter waypoints: The waypoints to be displayed on the map.
     - parameter legIndex: Index, which determines for which `RouteLeg` `Waypoint` will be shown.
     - returns: Optionally, a `FeatureCollection` that defines the shape of the waypoint, or `nil` to use default behavior.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection?
    
    // MARK: Responding to Object Interaction
    
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
     Tells the receiver that the final destination `PointAnnotation` was added to the `NavigationMapView`.
     
     - parameter navigationMapView: The `NavigationMapView` object.
     - parameter finalDestinationAnnotation: The point annotation that was added to the map view.
     - parameter pointAnnotationManager: The object that manages the point annotation in the map view.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, didAdd finalDestinationAnnotation: PointAnnotation, pointAnnotationManager: PointAnnotationManager)
}

public extension NavigationMapViewDelegate {
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, routeLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }

    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, routeCasingLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, routeRestrictedAreasLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }

    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, shapeFor route: Route) -> LineString? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, casingShapeFor route: Route) -> LineString? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationMapView(_ navigationMapView: NavigationMapView, restrictedAreasShapeFor route: Route) -> LineString? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }
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
    func navigationMapView(_ navigationMapView: NavigationMapView, shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection? {
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
    func navigationMapView(_ navigationMapView: NavigationMapView, didAdd finalDestinationAnnotation: PointAnnotation, pointAnnotationManager: PointAnnotationManager) {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
    }
}
