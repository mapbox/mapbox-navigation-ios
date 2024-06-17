import CoreGraphics
import CoreLocation
import Foundation
import MapboxDirections
import MapboxMaps
import MapboxNavigationCore

/// The ``NavigationViewControllerDelegate`` protocol provides methods for configuring the map view shown by a
/// ``NavigationViewController`` and responding to the cancellation of a navigation session.
public protocol NavigationViewControllerDelegate: VisualInstructionDelegate, UnimplementedLogging {
    // MARK: Monitoring Route Progress

    /// Called when the navigation view controller is dismissed, such as when the user ends a trip.
    /// - Parameters:
    ///   - navigationViewController: The navigation view controller that was dismissed.
    ///   - canceled: canceled: True if the user dismissed the navigation view controller by tapping the Cancel button;
    /// false if the navigation view controller dismissed by some other means.
    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    )

    /// Called when movement of the user updates the route progress model.
    /// - Parameters:
    ///   - navigationViewController: The ``NavigationViewController`` that received the new locations.
    ///   - progress: The `RouteProgress` model that was updated.
    ///   - location: The guaranteed location, possibly snapped, associated with the progress update.
    ///   - rawLocation: The raw location, from the location manager, associated with the progress update.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didUpdate progress: RouteProgress,
        with location: CLLocation,
        rawLocation: CLLocation
    )

    /// Called when the user arrives at the destination waypoint for a route leg.
    /// - Parameters:
    ///   - navigationViewController: The ``NavigationViewController``that has arrived at a waypoint.
    ///   - waypoint: The waypoint that the user has arrived at.
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint)

    // MARK: Interaction With Waypoints

    /// Tells the receiver that the final destination `PointAnnotation` was added to the ``NavigationViewController``.
    /// - Parameters:
    ///   - navigationViewController: The ``NavigationViewController`` object.
    ///   - finalDestinationAnnotation: The point annotation that was added to the map view.
    ///   - pointAnnotationManager: The object that manages the point annotation in the map view.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didAdd finalDestinationAnnotation: PointAnnotation,
        pointAnnotationManager: PointAnnotationManager
    )

    /// Tells the receiver that a waypoint was selected.
    /// - Parameters:
    ///   - navigationViewController: The ``NavigationViewController`` object.
    ///   - waypoint: The waypoint that was selected.
    func navigationViewController(_ navigationViewController: NavigationViewController, didSelect waypoint: Waypoint)

    // MARK: Rerouting and Refreshing the Route

    /// Called immediately before the navigation view controller calculates a new route.
    ///
    /// - Note: Multiple method calls will not interrupt the first ongoing request.
    ///
    /// - Parameters:
    ///   - navigationViewController: The ``NavigationViewController`` object.
    ///   - location: The user’s current location.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        willRerouteFrom location: CLLocation?
    )

    /// Called immediately after the navigation view controller receives a new route.
    ///
    /// This method is called after ``NavigationViewControllerDelegate/navigationViewController(_:willRerouteFrom:)``.
    ///
    /// - Parameters:
    ///   - navigationViewController: The ``NavigationViewController`` object.
    ///   - route: The new route.
    func navigationViewController(_ navigationViewController: NavigationViewController, didRerouteAlong route: Route)

    /// Called when navigation view controller has detected a change in alternative routes list.
    /// - Parameters:
    ///   - navigationViewController: The navigation view controller reporting an update.
    ///   - updatedAlternatives: Array of actual alternative routes.
    ///   - removedAlternatives:  Array of alternative routes which are no longer actual.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didUpdateAlternatives updatedAlternatives: [AlternativeRoute],
        removedAlternatives: [AlternativeRoute]
    )

    /// Called when navigation view controller has automatically switched to the coincide online route.
    /// - Parameters:
    ///   - navigationViewController: The navigation view controller reporting an update.
    ///   - coincideRoute: A route taken.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didSwitchToCoincidentOnlineRoute coincideRoute: Route
    )

    /// Tells the receiver that the user has selected a continuous alternative route by interacting with the map view.
    ///
    /// Continuous alternatives are all non-primary routes, reported during the navigation session.
    ///
    /// - Parameters:
    ///   - navigationViewController: The ``NavigationViewController`` object.
    ///   - alternative: The route that was selected.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didSelect alternative: AlternativeRoute
    )

    /// Called when the navigation view controller fails to receive a new route.
    ///
    /// This method is called after ``NavigationViewControllerDelegate/navigationViewController(_:willRerouteFrom:)``.
    /// - Parameters:
    ///   - navigationViewController: The ``NavigationViewController`` object.
    ///   - error: An error raised during the process of obtaining a new route.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didFailToRerouteWith error: Error
    )

    /// Called immediately after the navigation view controller refreshes the route.
    /// - Parameters:
    ///   - navigationViewController: The navigation view controller that has refreshed the route.
    ///   - routeProgress: The updated route progress with the refreshed route.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didRefresh routeProgress: RouteProgress
    )

    // MARK: Customizing the Route Elements

    /// Returns an `LineLayer` that determines the appearance of the route line.
    /// If this method is not implemented, the navigation view controller’s map view draws the route line using default
    /// `LineLayer`.
    /// - Parameters:
    ///   - navigationViewController: The ``NavigationViewController`` object, on surface of which route line is drawn.
    ///   - identifier: The `LineLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
    /// - Returns: A `LineLayer` that is applied to the route line.
    /// - SeeAlso: `NavigationMapViewDelegate/navigationMapView(_:routeLineLayerWithIdentifier:sourceIdentifier:)`,
    /// ``CarPlayManagerDelegate/carPlayManager(_:routeLineLayerWithIdentifier:sourceIdentifier:for:)``.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        routeLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer?

    /// Returns an `LineLayer` that determines the appearance of the casing around the route line.
    /// If this method is not implemented, the navigation view controller’s map view draws the casing for the route line
    /// using default `LineLayer`.
    /// - Parameters:
    ///   - navigationViewController: The ``NavigationViewController`` object, on surface of which route line is drawn.
    ///   - identifier: The `LineLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
    /// - Returns: A `LineLayer` that is applied as a casing around the route line.
    /// - SeeAlso:
    /// `NavigationMapViewDelegate/navigationMapView(_:routeCasingLineLayerWithIdentifier:sourceIdentifier:)`,
    /// ``CarPlayManagerDelegate/carPlayManager(_:routeCasingLineLayerWithIdentifier:sourceIdentifier:for:)``.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        routeCasingLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer?

    /// Returns an `LineLayer` that determines the appearance of the restricted areas portions of the route line.
    /// If this method is not implemented, the navigation view controller’s map view draws the areas using default
    /// `LineLayer`.
    /// - Parameters:
    ///   - navigationViewController: The ``NavigationViewController`` object, on surface of which route line is drawn.
    ///   - identifier: The `LineLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
    /// - Returns: A `LineLayer` that is applied as restricted areas on the route line.
    /// - SeeAlso:
    /// `NavigationMapViewDelegate/navigationMapView(_:routeCasingLineLayerWithIdentifier:sourceIdentifier:)`,
    /// ``CarPlayManagerDelegate/carPlayManager(_:routeRestrictedAreasLineLayerWithIdentifier:sourceIdentifier:for:)``.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        routeRestrictedAreasLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer?

    /// Asks the receiver to adjust the default layer which will be added to the map view and return a `Layer`.
    ///  If this method is not implemented, the navigation view controller’s map view draws the default `layer`.
    /// - Parameters:
    ///   - navigationViewController: The ``NavigationViewController`` object, on surface of which route line is drawn.
    ///   - layer: A default `Layer` generated by the navigationViewController.
    /// - Returns: An adjusted `Layer` that will be added to the navigation view controller’s map view by the SDK.
    /// - SeeAlso: `NavigationMapViewDelegate.navigationMapView(_:willAdd:)`,
    /// ``CarPlayManagerDelegate/carPlayManager(_:willAdd:for:)``.
    func navigationViewController(_ navigationViewController: NavigationViewController, willAdd layer: Layer) -> Layer?

    /// Returns an `CircleLayer` that marks the location of each destination along the route when there are multiple
    /// destinations. The returned layer is added to the map below the layer returned by ``NavigationViewControllerDelegate/navigationViewController(_:waypointSymbolLayerWithIdentifier:sourceIdentifier:)``.
    /// - Parameters:
    ///   - navigationViewController: The ``NavigationViewController`` object.
    ///   - identifier: The `CircleLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the waypoint data that this method would style.
    /// - Returns: A `CircleLayer` that the map applies to all intermediate waypoints.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer?

    /// Returns a `SymbolLayer` that places an identifying symbol on each destination along the route when there are
    /// multiple destinations. The returned layer is added to the map above the layer returned by ``NavigationViewControllerDelegate/navigationViewController(_:waypointCircleLayerWithIdentifier:sourceIdentifier:)``.
    /// - Parameters:
    ///   - navigationViewController: The ``NavigationViewController`` object.
    ///   - identifier: The `SymbolLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the waypoint data that this method would style.
    /// - Returns: A `SymbolLayer` that the map applies to all intermediate waypoint symbols.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer?

    /// Returns a `FeatureCollection` that represents intermediate waypoints along the route (that is, excluding the
    /// origin).
    ///
    /// If this method is unimplemented, the navigation view controller's map view draws the waypoints using default
    /// `FeatureCollection`.
    /// - Parameters:
    ///   - navigationViewController: The ``NavigationViewController`` object.
    ///   - waypoints: The intermediate waypoints to be displayed on the map.
    ///   - legIndex: The index of the current leg during navigation.
    /// - Returns: Optionally, a `FeatureCollection` that defines the shape of the waypoint, or `nil` to use default
    /// behavior.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        shapeFor waypoints: [Waypoint],
        legIndex: Int
    ) -> FeatureCollection?

    /// Called to allow the delegate to customize the contents of the road name label that is displayed towards the
    /// bottom of the map view.
    ///
    /// This method is called on each location update. By default, the label displays the name of the road the user is
    /// currently traveling on.
    /// - Parameters:
    ///   - navigationViewController: The navigation view controller that will display the road name.
    ///   - location: The user’s current location.
    /// - Returns: The road name to display in the label, or nil to hide the label.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        roadNameAt location: CLLocation
    ) -> String?

    // MARK: Filtering Location Updates

    /// Called to notify that the user submitted the end of route feedback.
    /// - Parameters:
    ///   - navigationViewController: The ``NavigationViewController`` object.
    ///   - isPositive: A `Boolean` value that indicates if the feedback submitted by the user was positive.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didSubmitArrivalFeedback isPositive: Bool
    )
}

extension NavigationViewControllerDelegate {
    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didUpdate progress: RouteProgress,
        with location: CLLocation,
        rawLocation: CLLocation
    ) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didArriveAt waypoint: Waypoint
    ) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didSelect waypoint: Waypoint
    ) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        willRerouteFrom location: CLLocation?
    ) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didRerouteAlong route: Route
    ) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didUpdateAlternatives updatedAlternatives: [AlternativeRoute],
        removedAlternatives: [AlternativeRoute]
    ) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didSwitchToCoincidentOnlineRoute coincideRoute: Route
    ) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didSelect continuousAlternative: AlternativeRoute
    ) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didFailToRerouteWith error: Error
    ) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didRefresh routeProgress: RouteProgress
    ) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        shapeFor waypoints: [Waypoint],
        legIndex: Int
    ) -> FeatureCollection? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        routeLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        routeCasingLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        routeRestrictedAreasLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        willAdd layer: Layer
    ) -> Layer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        roadNameAt location: CLLocation
    ) -> String? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didAdd finalDestinationAnnotation: PointAnnotation,
        pointAnnotationManager: PointAnnotationManager
    ) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didSubmitArrivalFeedback isPositive: Bool
    ) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }
}
