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
    @available(
        *,
        deprecated,
        message: "This method is deprecated and should no longer be used, as the final destination annotation is no longer added to the map. Use the corresponding delegate methods to customize waypoints appearance."
    )
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        didAdd finalDestinationAnnotation: PointAnnotation,
        pointAnnotationManager: PointAnnotationManager
    )

    // MARK: Customizing Waypoint(s) Appearance

    /// Asks the receiver to return a `CircleLayer` for waypoints, given an identifier and source.
    /// The returned layer is added to the map below the layer returned by  ``CarPlayNavigationViewControllerDelegate/carPlayNavigationViewController(_:waypointSymbolLayerWithIdentifier:sourceIdentifier:)``.
    /// This method is invoked any time waypoints are added or shown.
    /// - Parameters:
    ///   - carPlayNavigationViewController: The ``CarPlayNavigationViewController`` object.
    ///   - identifier: The `CircleLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the waypoint data that this method would style.
    /// - Returns: A `CircleLayer` that the map applies to all waypoints.
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer?

    /// Asks the receiver to return a `SymbolLayer` for waypoint symbols, given an identifier and source.
    /// The returned layer is added to the map above the layer returned by ``CarPlayNavigationViewControllerDelegate/carPlayNavigationViewController(_:waypointCircleLayerWithIdentifier:sourceIdentifier:)``.
    /// This method is invoked any time waypoints are added or shown.
    /// - Parameters:
    ///   - carPlayNavigationViewController: The ``CarPlayNavigationViewController`` object.
    ///   - identifier: The `SymbolLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the waypoint data that this method would style.
    /// - Returns: A `SymbolLayer` that the map applies to all waypoint symbols.
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer?

    /// Asks the receiver to return a `FeatureCollection` that describes the geometry of waypoints.
    ///
    /// For example, to customize the appearance of intermediate waypoints by adding an image follow these steps:
    ///
    /// 1. Implement the
    /// ``CarPlayNavigationViewControllerDelegate/carPlayNavigationViewController(_:shapeFor:legIndex:)``
    /// method to provide a
    /// `FeatureCollection` for waypoints.
    /// Within this method:
    ///     1. Add an image to the map by calling `MapboxMap.addImage(_:id:stretchX:stretchY:)` method.
    ///     2. Iterate through the `waypoints` array and create `Feature` for each waypoint.
    ///     3. Add a key-value pair to `Feature.properties` for specifying an icon image if the waypoint is
    ///     intermediate.
    ///
    /// Example:
    ///
    /// ```swift
    /// func carPlayNavigationViewController(
    ///     _ carPlayNavigationViewController: CarPlayNavigationViewController,
    ///     shapeFor waypoints: [Waypoint],
    ///     legIndex: Int
    /// ) -> FeatureCollection? {
    ///     guard let navigationMapView = carPlayNavigationViewController.navigationMapView else { return nil }
    ///
    ///     let imageId = "intermediateWaypointImageId"
    ///     if !navigationMapView.mapView.mapboxMap.imageExists(withId: imageId) {
    ///         do {
    ///             try navigationMapView.mapView.mapboxMap.addImage(
    ///                 UIImage(named: "waypoint")!,
    ///                 id: imageId,
    ///                 stretchX: [],
    ///                 stretchY: []
    ///             )
    ///         } catch {
    ///             // Handle the error
    ///             return nil
    ///         }
    ///     }
    ///     return FeatureCollection(
    ///         features: waypoints.enumerated().map { waypointIndex, waypoint in
    ///             var feature = Feature(geometry: .point(Point(waypoint.coordinate)))
    ///             var properties: [String: JSONValue] = [:]
    ///             properties["waypointCompleted"] = .boolean(waypointIndex <= legIndex)
    ///             properties["waypointIconImage"] = waypointIndex > 0 && waypointIndex < waypoints.count - 1
    ///             ? .string(imageId)
    ///             : nil
    ///             feature.properties = properties
    ///             return feature
    ///         }
    ///     )
    /// }
    /// ```
    ///
    /// 2. Implement the
    /// ``CarPlayNavigationViewControllerDelegate/carPlayNavigationViewController(_:waypointSymbolLayerWithIdentifier:sourceIdentifier:)``
    /// method to provide a custom `SymbolLayer`.
    ///     1. Create a `SymbolLayer`.
    ///     2. Set `SymbolLayer.iconImage` to an expression `Exp` to retrieve the icon image name based on the
    ///     properties defined in step 1.3.
    ///
    /// Example:
    /// ```swift
    /// func carPlayNavigationViewController(
    ///     _ carPlayNavigationViewController: CarPlayNavigationViewController,
    ///     waypointSymbolLayerWithIdentifier identifier: String,
    ///     sourceIdentifier: String
    /// ) -> SymbolLayer? {
    ///
    ///     var symbolLayer = SymbolLayer(id: identifier, source: sourceIdentifier)
    ///     let opacity = Exp(.switchCase) {
    ///         Exp(.any) {
    ///             Exp(.get) {
    ///                 "waypointCompleted"
    ///             }
    ///         }
    ///         0
    ///         1
    ///     }
    ///     symbolLayer.iconOpacity = .expression(opacity)
    ///     symbolLayer.iconImage = .expression(Exp(.get) { "waypointIconImage" })
    ///     symbolLayer.iconAnchor = .constant(.bottom)
    ///     symbolLayer.iconOffset = .constant([0, 15])
    ///     symbolLayer.iconAllowOverlap = .constant(true)
    ///     return symbolLayer
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - carPlayNavigationViewController: The ``CarPlayNavigationViewController`` object.
    ///   - waypoints: The waypoints to be displayed on the map.
    ///   - legIndex: The index of the current leg during navigation.
    /// - Returns: Optionally, a `FeatureCollection` that defines the shape of the waypoint, or `nil` to use the default
    /// behavior.
    func carPlayNavigationViewController(
        _ carPlayNavigationViewController: CarPlayNavigationViewController,
        shapeFor waypoints: [Waypoint],
        legIndex: Int
    ) -> FeatureCollection?

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
