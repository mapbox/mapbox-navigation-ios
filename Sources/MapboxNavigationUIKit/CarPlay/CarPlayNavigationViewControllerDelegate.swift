import MapboxDirections
import MapboxMaps
import MapboxNavigationCore
import UIKit

/// The ``CarPlayNavigationViewControllerDelegate`` protocol provides methods for reacting to significant events during
/// turn-by-turn navigation with ``CarPlayNavigationViewController``.
public protocol CarPlayNavigationViewControllerDelegate: AnyObject, UnimplementedLogging {
    /// Called when the CarPlay navigation view controller is about to be dismissed, such as when the user ends a trip.
    /// - Parameters:
    ///   - carPlayNavigationViewController: The CarPlay navigation view controller that was dismissed.
    ///   - canceled: True if the user dismissed the CarPlay navigation view controller by tapping the Cancel button;
    /// false if the navigation view controller dismissed by some other means.
    func carPlayNavigationViewControllerWillDismiss(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        byCanceling canceled: Bool
    )
    /// Called when the CarPlay navigation view controller is dismissed, such as when the user ends a trip.
    /// - Parameters:
    ///   - carPlayNavigationViewController: The CarPlay navigation view controller that was dismissed.
    ///   - canceled: True if the user dismissed the CarPlay navigation view controller by tapping the Cancel button;
    /// false if the navigation view controller dismissed by some other means.
    func carPlayNavigationViewControllerDidDismiss(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        byCanceling canceled: Bool
    )

    /// Called when the CarPlay navigation view controller detects an arrival.
    /// - Parameters:
    ///   - carPlayNavigationViewController: The CarPlay navigation view controller that has arrived at a waypoint.
    ///   - waypoint: The waypoint that the user has arrived at.
    /// - Returns: A boolean value indicating whether to show an arrival UI.
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        shouldPresentArrivalUIFor waypoint: Waypoint
    ) -> Bool

    ///  Tells the receiver that the final destination `PointAnnotation` was added to the
    /// ``CarPlayNavigationViewController``.
    /// - Parameters:
    ///   - carPlayNavigationViewController: The ``CarPlayNavigationViewController`` object.
    ///   - finalDestinationAnnotation: The point annotation that was added to the map view.
    ///   - pointAnnotationManager: The object that manages the point annotation in the map view.
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        didAdd finalDestinationAnnotation: PointAnnotation,
        pointAnnotationManager: PointAnnotationManager
    )

    /// Returns a `FeatureCollection` that represents intermediate waypoints along the route (that is, excluding the
    /// origin).
    ///
    /// If this method is unimplemented, the navigation view controller's map view draws the waypoints using default
    /// `FeatureCollection`.
    /// - Parameters:
    ///   - carPlayNavigationViewController: The ``CarPlayNavigationViewController`` object.
    ///   - waypoints: The intermediate waypoints to be displayed on the map.
    ///   - legIndex: The index of the current leg during navigation.
    /// - Returns: A `FeatureCollection` that represents intermediate waypoints along the route (that is, excluding the
    /// origin).
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        shapeFor waypoints: [Waypoint],
        legIndex: Int
    ) -> FeatureCollection?

    /// Asks the receiver to return a `SymbolLayer` for waypoint symbols, given an identifier and source.
    /// This method is invoked any time waypoints are added or shown.
    /// - Parameters:
    ///   - carPlayNavigationViewController: The ``CarPlayNavigationViewController`` object.
    ///   - identifier: The `SymbolLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the waypoint data that this method would style.
    /// - Returns: A `SymbolLayer` that the map applies to all intermediate waypoint symbols.
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer?

    /// Asks the receiver to return a `CircleLayer` for waypoints, given an identifier and source.
    /// This method is invoked any time waypoints are added or shown.
    /// - Parameters:
    ///   - carPlayNavigationViewController: The ``CarPlayNavigationViewController`` object.
    ///   - identifier: The `CircleLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the waypoint data that this method would style.
    /// - Returns: A `CircleLayer` that the map applies to all intermediate waypoints.
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer?

    /// Asks the receiver to return a `LineLayer` for the route line, given a layer identifier and a source identifier.
    /// This method is invoked when the map view loads and any time routes are added.
    /// - Parameters:
    ///   - carPlayNavigationViewController: The ``CarPlayNavigationViewController`` object.
    ///   - identifier: The `LineLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
    /// - Returns: A `LineLayer` that is applied to the route line.
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        routeLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer?

    /// Asks the receiver to return a `LineLayer` for the casing layer that surrounds route line, given a layer
    /// identifier and a source identifier.
    /// This method is invoked when the map view loads and any time routes are added.
    /// - Parameters:
    ///   - carPlayNavigationViewController: The ``CarPlayNavigationViewController`` object.
    ///   - identifier: The `LineLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
    /// - Returns: A `LineLayer` that is applied as a casing around the route line.
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        routeCasingLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer?

    /// Asks the receiver to return a `LineLayer` for highlighting restricted areas portions of the route, given a layer
    /// identifier and a source identifier.
    /// This method is invoked when the map view loads and any time routes are added.
    /// - Parameters:
    ///   - carPlayNavigationViewController: The ``CarPlayNavigationViewController`` object.
    ///   - identifier: The `LineLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
    /// - Returns: A `LineLayer` that is applied as restricted areas on the route line.
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        routeRestrictedAreasLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer?

    /// Asks the receiver to adjust the default layer which will be added to the map view and return a `Layer`.
    /// This method is invoked when the map view loads and any time a layer will be added.
    /// - Parameters:
    ///   - carPlayNavigationViewController: The ``CarPlayNavigationViewController`` object.
    ///   - layer: A default `Layer` generated by the carPlayNavigationViewController.
    /// - Returns: An adjusted `Layer` that will be added to the map view by the SDK.
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        willAdd layer: Layer
    ) -> Layer?

    /// Asks the receiver to adjust the default color of the main instruction background color for a specific user
    /// interface style.
    ///  According to `CPMapTemplate.guidanceBackgroundColor` Navigation SDK can't guarantee that a custom color
    /// returned in this function will be actually applied, it's up to CarPlay.
    /// - Parameters:
    ///   - carPlayNavigationViewController: The ``CarPlayNavigationViewController`` object.
    ///   - style: A default `UIUserInterfaceStyle` generated by the system.
    /// - Returns: A `UIColor` which will be used to update `CPMapTemplate.guidanceBackgroundColor`.
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        guidanceBackgroundColorFor style: UIUserInterfaceStyle
    ) -> UIColor?
}

extension CarPlayNavigationViewControllerDelegate {
    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayNavigationViewControllerWillDismiss(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        byCanceling canceled: Bool
    ) {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayNavigationViewControllerDidDismiss(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        byCanceling canceled: Bool
    ) {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        shouldPresentArrivalUIFor waypoint: Waypoint
    ) {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        didAdd finalDestinationAnnotation: PointAnnotation,
        pointAnnotationManager: PointAnnotationManager
    ) {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer? {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer? {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        routeLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        routeCasingLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        routeRestrictedAreasLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        willAdd layer: Layer
    ) -> Layer? {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        guidanceBackgroundColorFor style: UIUserInterfaceStyle
    ) -> UIColor? {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .debug)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        shapeFor waypoints: [Waypoint],
        legIndex: Int
    ) -> FeatureCollection? {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .debug)
        return nil
    }
}
