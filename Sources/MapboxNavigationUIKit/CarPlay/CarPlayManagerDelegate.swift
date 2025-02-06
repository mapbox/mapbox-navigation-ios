import CarPlay
import MapboxDirections
import MapboxMaps
import MapboxNavigationCore
import Turf
import UIKit

/// ``CarPlayManagerDelegate`` is the main integration point for Mapbox CarPlay support.
/// Implement this protocol and assign an instance to the ``CarPlayManager/delegate`` property.
public protocol CarPlayManagerDelegate: AnyObject, UnimplementedLogging {
    // MARK: Customizing the Bar Buttons

    /// Offers the delegate an opportunity to provide a customized list of leading bar buttons at the root of the
    /// template stack for the given activity.
    ///
    /// These buttons' tap handlers encapsulate the action to be taken, so it is up to the developer to ensure the
    /// hierarchy of templates is adequately navigable.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` instance.
    ///   - traitCollection: The trait collection of the view controller being shown in the CarPlay window.
    ///   - carPlayTemplate: The template into which the returned bar buttons will be inserted.
    ///   - activity: What the user is currently doing on the CarPlay screen. Use this parameter to distinguish between
    /// multiple templates of the same kind, such as multiple `CPMapTemplate`s.
    /// - Returns: An array of bar buttons to display on the leading side of the navigation bar while `template` is
    /// visible.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        in carPlayTemplate: CPMapTemplate,
        for activity: CarPlayActivity
    ) -> [CPBarButton]?

    /// Offers the delegate an opportunity to provide a customized list of leading bar buttons at the root of the
    /// template stack for the given activity.
    ///
    /// These buttons' tap handlers encapsulate the action to be taken, so it is up to the developer to ensure the
    /// hierarchy of templates is adequately navigable.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` instance.
    ///   - traitCollection: The trait collection of the view controller being shown in the CarPlay window.
    ///   - carPlayTemplate: The template into which the returned bar buttons will be inserted.
    ///   - activity: What the user is currently doing on the CarPlay screen. Use this parameter to distinguish between
    /// multiple templates of the same kind, such as multiple `CPMapTemplate`s.
    /// - Returns: An array of bar buttons to display on the leading side of the navigation bar while `template` is
    /// visible.
    @available(
        *,
        deprecated,
        message: "Use carPlayManager(_:leadingNavigationBarButtonsCompatibleWith:in:for:) instead."
    )
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        in carPlayTemplate: CPTemplate,
        for activity: CarPlayActivity
    ) -> [CPBarButton]?

    /// Offers the delegate an opportunity to provide a customized list of trailing bar buttons at the root of the
    /// template stack for the given activity.
    ///
    /// These buttons' tap handlers encapsulate the action to be taken, so it is up to the developer to ensure the
    /// hierarchy of templates is adequately navigable.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` instance.
    ///   - traitCollection: The trait collection of the view controller being shown in the CarPlay window.
    ///   - carPlayTemplate: The template into which the returned bar buttons will be inserted.
    ///   - activity: What the user is currently doing on the CarPlay screen. Use this parameter to distinguish between
    /// multiple templates of the same kind, such as multiple `CPMapTemplate`s.
    /// - Returns: An array of bar buttons to display on the trailing side of the navigation bar while `template` is
    /// visible.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        in carPlayTemplate: CPMapTemplate,
        for activity: CarPlayActivity
    ) -> [CPBarButton]?

    /// Offers the delegate an opportunity to provide a customized list of trailing bar buttons at the root of the
    /// template stack for the given activity.
    ///
    /// These buttons' tap handlers encapsulate the action to be taken, so it is up to the developer to ensure the
    /// hierarchy of templates is adequately navigable.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` instance.
    ///   - traitCollection: The trait collection of the view controller being shown in the CarPlay window.
    ///   - carPlayTemplate: The template into which the returned bar buttons will be inserted.
    ///   - activity: What the user is currently doing on the CarPlay screen. Use this parameter to distinguish between
    /// multiple templates of the same kind, such as multiple `CPMapTemplate`s.
    /// - Returns: An array of bar buttons to display on the trailing side of the navigation bar while `template` is
    /// visible.
    @available(
        *,
        deprecated,
        message: "Use carPlayManager(_:trailingNavigationBarButtonsCompatibleWith:in:for:) instead."
    )
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        in carPlayTemplate: CPTemplate,
        for activity: CarPlayActivity
    ) -> [CPBarButton]?

    /// Offers the delegate an opportunity to provide a customized list of buttons displayed on the map.
    ///
    /// These buttons handle the gestures on the map view, so it is up to the developer to ensure the map template is
    /// interactive.
    ///
    /// If this method is not implemented, or if nil is returned, a default set of zoom and pan buttons declared in the
    /// `CarPlayMapViewController` will be provided.
    ///
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` instance.
    ///   -  traitCollection: The trait collection of the view controller being shown in the CarPlay window.
    ///   -  carPlayTemplate: The template into which the returned map buttons will be inserted.
    ///   -  activity: What the user is currently doing on the CarPlay screen. Use this parameter to distinguish between
    /// multiple templates of the same kind, such as multiple `CPMapTemplate`s.
    /// - Returns: An array of map buttons to display on the map while `template` is visible.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        mapButtonsCompatibleWith traitCollection: UITraitCollection,
        in carPlayTemplate: CPTemplate,
        for activity: CarPlayActivity
    ) -> [CPMapButton]?

    // MARK: Previewing a Route

    /// Offers the delegate the opportunity to customize a trip before it is presented to the user to preview.
    ///
    /// To customize the destination’s title, which is displayed when a route is selected, set the  `MKMapItem.name`
    /// property of the `CPTrip.destination` property. To add a subtitle, create a new `MKMapItem` whose `MKPlacemark`
    /// has the `Street` key in its address dictionary.
    ///
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` instance.
    ///   - trip: The trip that will be previewed.
    /// - Returns: The actual trip to be previewed. This can be the same trip or a new/alternate trip if desired.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        willPreview trip: CPTrip
    ) -> CPTrip

    /// Offers the delegate the opportunity to customize a trip preview text configuration for a given trip.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` instance.
    ///   - trip: The trip that will be previewed.
    ///   - previewTextConfiguration:  The trip preview text configuration that will be presented alongside the trip.
    /// - Returns: The actual preview text configuration to be presented alongside the trip.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        willPreview trip: CPTrip,
        with previewTextConfiguration: CPTripPreviewTextConfiguration
    ) -> CPTripPreviewTextConfiguration

    /// Offers the delegate the opportunity to react to selection of a trip. Certain trips may have alternate route(s).
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` instance.
    ///   - trip: The trip to begin navigating along.
    ///   - routeChoice: The possible route for the chosen trip.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        selectedPreviewFor trip: CPTrip,
        using routeChoice: CPRouteChoice
    )

    /// Called when CarPlay will cancel routes preview.
    /// This delegate method will be called before canceling the routes preview.
    ///
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` instance.
    ///   - configuration: The configuration of the cancel preview action.
    func carPlayManagerWillCancelPreview(
        _ carPlayManager: CarPlayManager,
        configuration: inout CarPlayManagerCancelPreviewConfiguration
    )

    /// Called when CarPlay canceled routes preview.
    /// This delegate method will be called after canceled the routes preview.
    ///
    /// - Parameter carPlayManager: The ``CarPlayManager`` instance.
    func carPlayManagerDidCancelPreview(_ carPlayManager: CarPlayManager)

    // MARK: Monitoring Route Progress and Updates

    /// Called when the CarPlay manager fails to fetch a route.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` instance.
    ///   - waypoints: the waypoints for which a route could not be retrieved.
    ///   - options: The route options that were attached to the route request.
    ///   - error: The error returned from the directions API.
    /// - Returns: Optionally, a `CPNavigationAlert` to present to the user. If this method returns an alert, the
    /// CarPlay manager will transition back to the map template and display the alert.
    /// If it returns `nil`, the CarPlay manager will do nothing.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didFailToFetchRouteBetween waypoints: [Waypoint]?,
        options: RouteOptions,
        error: Error
    ) -> CPNavigationAlert?

    /// Called when navigation begins so that the containing app can update accordingly.
    ///
    /// - Parameter carPlayManager: The ``CarPlayManager`` instance.
    func carPlayManagerDidBeginNavigation(_ carPlayManager: CarPlayManager)

    /// Called when navigation is about to be finished so that the containing app can update accordingly.
    /// This delegate method will be called before dismissing ``CarPlayNavigationViewController``.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` instance.
    ///   - canceled: A `Boolean` value indicating whether this method is being called because the user intends to
    /// cancel the trip, as opposed to letting it run to completion.
    func carPlayManagerWillEndNavigation(_ carPlayManager: CarPlayManager, byCanceling canceled: Bool)

    /// Called when navigation ends so that the containing app can update accordingly.
    /// This delegate method will be called after dismissing ``CarPlayNavigationViewController``.
    ///
    /// If you need to know whether the navigation ended because the user arrived or canceled it, use the
    /// ``CarPlayManagerDelegate/carPlayManagerDidEndNavigation(_:byCanceling:)`` method.
    ///
    /// - Parameter carPlayManager: The ``CarPlayManager`` instance.
    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager)

    /// Called when navigation ends so that the containing app can update accordingly.
    /// This delegate method will be called after dismissing ``CarPlayNavigationViewController``.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` instance.
    ///   - canceled: A `Boolean` value indicating whether this method is being called because the user canceled the
    /// trip, as opposed to letting it run to completion/being canceled by the system.
    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager, byCanceling canceled: Bool)

    /// Called when the ``CarPlayManager`` detects the user arrives at the destination waypoint for a route leg.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` instance that has arrived at a waypoint.
    ///   - waypoint: The waypoint that the user has arrived at.
    /// - Returns: A `Boolean` value indicating whether to show an arrival UI.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        shouldPresentArrivalUIFor waypoint: Waypoint
    ) -> Bool

    /// Called when the carplay manager will disable the idle timer.
    ///
    /// Implementing this method will allow developers to change whether idle timer is disabled when CarPlay is
    /// connected and the vice-versa when disconnected.
    ///
    /// - Parameter carPlayManager: The ``CarPlayManager`` instance.
    /// - Returns: A Boolean value indicating whether to disable idle timer when carplay is connected and enable when
    /// disconnected.
    func carPlayManagerShouldDisableIdleTimer(_ carPlayManager: CarPlayManager) -> Bool

    /// Called when the ``CarPlayManager`` creates a new ``CarPlayNavigationViewController`` upon start of a navigation
    /// session.
    /// Implementing this method will allow developers to query or customize properties of the
    /// ``CarPlayNavigationViewController`` before it is presented. For example, a developer may wish to perform custom
    /// map styling on the presented `NavigationMapView`.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - navigationViewController: The ``CarPlayNavigationViewController`` that will be presented on the CarPlay
    /// display.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        willPresent navigationViewController: CarPlayNavigationViewController
    )

    /// Called when the ``CarPlayManager`` presents a new ``CarPlayNavigationViewController`` upon start of a navigation
    /// session.
    ///
    /// Implementing this method will allow developers to query or customize properties of the presented
    /// ``CarPlayNavigationViewController``. For example, a developer may wish to perform custom map styling on the
    /// presented `NavigationMapView`.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - navigationViewController: The ``CarPlayNavigationViewController`` that was presented on the CarPlay display.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didPresent navigationViewController: CarPlayNavigationViewController
    )

    /// Tells the receiver that the `PointAnnotation` representing the final destination was added to either
    /// ``CarPlayMapViewController`` or ``CarPlayNavigationViewController``.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - finalDestinationAnnotation: The point annotation that was added to the map view.
    ///   - parentViewController: The view controller that contains the map view, which is an instance of either
    /// ``CarPlayMapViewController`` or ``CarPlayNavigationViewController``.
    ///   - pointAnnotationManager: The object that manages the point annotation in the map view.
    @available(
        *,
        deprecated,
        message: "This method is deprecated and should no longer be used, as the final destination annotation is no longer added to the map. Use the corresponding delegate methods to customize waypoints appearance."
    )
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didAdd finalDestinationAnnotation: PointAnnotation,
        to parentViewController: UIViewController,
        pointAnnotationManager: PointAnnotationManager
    )

    // MARK: Customizing Waypoint(s) Appearance

    /// Asks the receiver to return a `CircleLayer` for waypoints, given an identifier and source.
    /// The returned layer is added to the map below the layer returned by
    /// ``CarPlayManagerDelegate/carPlayManager(_:waypointSymbolLayerWithIdentifier:sourceIdentifier:)``.
    /// This method is invoked any time waypoints are added or shown.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - identifier: The `CircleLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the waypoint data that this method would style.
    /// - Returns: A `CircleLayer` that the map applies to all waypoints.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer?

    /// Asks the receiver to return a `SymbolLayer` for waypoint symbols, given an identifier and source.
    /// The returned layer is added to the map above the layer returned by
    /// ``CarPlayManagerDelegate/carPlayManager(_:waypointCircleLayerWithIdentifier:sourceIdentifier:)``.
    /// This method is invoked any time waypoints are added or shown.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - identifier: The `SymbolLayer` identifier.
    ///   - sourceIdentifier:  Identifier of the source, which contains the waypoint data that this method would style.
    /// - Returns: A `SymbolLayer` that the map applies to all waypoint symbols.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer?

    /// Asks the receiver to return a `FeatureCollection` that describes the geometry of waypoints.
    ///
    /// For example, to customize the appearance of intermediate waypoints by adding an image follow these steps:
    ///
    /// 1. Implement the ``CarPlayManagerDelegate/carPlayManager(_:shapeFor:legIndex:)``
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
    /// func carPlayManager(
    ///     _ carPlayManager: CarPlayManager,
    ///     shapeFor waypoints: [Waypoint],
    ///     legIndex: Int
    /// ) -> FeatureCollection? {
    ///     guard let navigationMapView = carPlayManager.navigationMapView else { return nil }
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
    /// ``CarPlayManagerDelegate/carPlayManager(_:waypointSymbolLayerWithIdentifier:sourceIdentifier:)``
    /// method to provide a custom `SymbolLayer`.
    ///     1. Create a `SymbolLayer`.
    ///     2. Set `SymbolLayer.iconImage` to an expression `Exp` to retrieve the icon image name based on the
    ///     properties defined in step 1.3.
    ///
    /// Example:
    /// ```swift
    /// func carPlayManager(
    ///     _ carPlayManager: CarPlayManager,
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
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - waypoints: The waypoints to be displayed on the map.
    ///   - legIndex: The index of the current leg during navigation.
    /// - Returns: Optionally, a `FeatureCollection` that defines the shape of the waypoint, or `nil` to use the default
    /// behavior.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        shapeFor waypoints: [Waypoint],
        legIndex: Int
    ) -> FeatureCollection?

    // MARK: Transitioning Between Templates

    /// Called when a template presented by the `CarPlayManager` is about to appear on the screen.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - template: The template to show.
    ///   - animated: A Boolean value indicating whether the system animates the presentation of the template.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        templateWillAppear template: CPTemplate,
        animated: Bool
    )

    /// Called when a template presented by the `CarPlayManager` has finished appearing on the screen.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - template: The template shown onscreen.
    ///   - animated: A Boolean value indicating whether the system animated the presentation of the template.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        templateDidAppear template: CPTemplate,
        animated: Bool
    )

    /// Called when a template presented by the `CarPlayManager` is about to disappear from the screen.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - template: The template that will disappear from the screen.
    ///   - animated: A Boolean value indicating whether the system animates the disappearance of the template.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        templateWillDisappear template: CPTemplate,
        animated: Bool
    )

    /// Called when a template presented by the `CarPlayManager` has finished disappearing from the screen.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - template: The template that disappeared from the screen.
    ///   - animated: A Boolean value indicating whether the system animated the disappearance of the template.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        templateDidDisappear template: CPTemplate,
        animated: Bool
    )

    /// Asks the receiver to return a `LineLayer` for the route line, given a layer identifier and a source identifier.
    /// This method is invoked when the map view loads and any time routes are added.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - identifier: The `LineLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
    ///   - parentViewController: The view controller that contains the map view, which is an instance of either
    /// ``CarPlayMapViewController`` or ``CarPlayNavigationViewController``.
    /// - Returns: A `LineLayer` that is applied to the route line.
    /// - SeeAlso: ``CarPlayNavigationViewControllerDelegate/carPlayNavigationViewController(_:routeLineLayerWithIdentifier:sourceIdentifier:)``,
    ///  ``CarPlayMapViewControllerDelegate/carPlayMapViewController(_:routeLineLayerWithIdentifier:sourceIdentifier:)``.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        routeLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String,
        for parentViewController: UIViewController
    ) -> LineLayer?

    /// Asks the receiver to return a `LineLayer` for the casing layer that surrounds route line, given a layer
    /// identifier and a source identifier.
    /// This method is invoked when the map view loads and any time routes are added.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - identifier: The `LineLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
    ///   - parentViewController: The view controller that contains the map view, which is an instance of either
    /// ``CarPlayMapViewController`` or ``CarPlayNavigationViewController``.
    /// - Returns: A `LineLayer` that is applied as a casing around the route line.
    /// - SeeAlso: ``CarPlayNavigationViewControllerDelegate/carPlayNavigationViewController(_:routeCasingLineLayerWithIdentifier:sourceIdentifier:)``,
    /// ``CarPlayMapViewControllerDelegate/carPlayMapViewController(_:routeCasingLineLayerWithIdentifier:sourceIdentifier:)``.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        routeCasingLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String,
        for parentViewController: UIViewController
    ) -> LineLayer?

    /// Asks the receiver to return a `LineLayer` for highlighting restricted areas portions of the route, given a layer
    /// identifier and a source identifier.
    /// This method is invoked when the map view loads and any time routes are added.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - identifier: The `LineLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
    ///   - parentViewController: The view controller that contains the map view, which is an instance of either
    /// ``CarPlayMapViewController`` or ``CarPlayNavigationViewController``.
    /// - Returns: A `LineLayer` that is applied as restricted areas on the route line.
    /// - SeeAlso: ``CarPlayNavigationViewControllerDelegate/carPlayNavigationViewController(_:routeRestrictedAreasLineLayerWithIdentifier:sourceIdentifier:)``,
    /// ``CarPlayMapViewControllerDelegate/carPlayMapViewController(_:routeRestrictedAreasLineLayerWithIdentifier:sourceIdentifier:)``.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        routeRestrictedAreasLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String,
        for parentViewController: UIViewController
    ) -> LineLayer?

    /// Asks the receiver to adjust the default layer which will be added to the map view and return a `Layer`.
    /// This method is invoked when the map view loads and any time a layer are added.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - layer: A default `Layer` generated by the carPlayManager.
    ///   - parentViewController: The view controller that contains the map view, which is an instance of either
    /// ``CarPlayMapViewController`` or ``CarPlayNavigationViewController``.
    /// - Returns: An adjusted `Layer` that will be added to the map view by the SDK.
    /// - SeeAlso: ``CarPlayNavigationViewControllerDelegate/carPlayNavigationViewController(_:willAdd:)`` and
    /// ``CarPlayMapViewControllerDelegate/carPlayMapViewController(_:willAdd:)``.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        willAdd layer: Layer,
        for parentViewController: UIViewController
    ) -> Layer?

    // MARK: Map Panning

    /// Called when the system detects a user starting to pan a map template visible on the screen.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - template: The template on which the gesture was started.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didBeginPanGesture template: CPMapTemplate
    )

    /// Called when the system detects a user stops panning a map template.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - template: The template on which the gesture was ended.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didEndPanGesture template: CPMapTemplate
    )

    /// Called when the pan interface appears on the map template.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - template: The template on which the panning interface is shown.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didShowPanningInterface template: CPMapTemplate
    )

    /// Called when the panning interface will disappear on a map template.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - template: The template on which the panning interface will be dismissed.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        willDismissPanningInterface template: CPMapTemplate
    )

    /// Called when the panning interface disappeared on a map template.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - template: The template on which the panning interface was dismissed.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didDismissPanningInterface template: CPMapTemplate
    )

    // MARK: Notifications Management

    /// Determines if the maneuver should be presented as a notification when the app is in the background.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - maneuver: Maneuver, for which notification will be shown.
    ///   - mapTemplate: The map template that is visible during either preview or navigation sessions.
    /// - Returns: A `Boolean` value indicating whether maneuver should appear as a notification.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        shouldShowNotificationFor maneuver: CPManeuver,
        in mapTemplate: CPMapTemplate
    ) -> Bool

    /// Determines if the updated distance remaining for the maneuver should be presented as a notification when the app
    /// is in the background.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - navigationAlert: Banner alert, for which notification will be shown.
    ///   - mapTemplate: The map template that is visible during either preview or navigation sessions.
    /// - Returns: A boolean value indicating whether alert should appear as a notification.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        shouldShowNotificationFor navigationAlert: CPNavigationAlert,
        in mapTemplate: CPMapTemplate
    ) -> Bool

    /// Determines if the navigation alert should be presented as a notification when the app is in the background.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - maneuver: Maneuver, for which notification will be shown.
    ///   - travelEstimates: Object that describes the time and distance remaining for the active navigation session.
    ///   - mapTemplate: The map template that is visible during either preview or navigation sessions.
    /// - Returns: A `Boolean` value indicating whether updated estimates should appear in the otification.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        shouldUpdateNotificationFor maneuver: CPManeuver,
        with travelEstimates: CPTravelEstimates,
        in mapTemplate: CPMapTemplate
    ) -> Bool

    /// Asks the receiver to adjust the default color of the main instruction background color for a specific user
    /// interface style.
    /// According to `CPMapTemplate.guidanceBackgroundColor` Navigation SDK can't guarantee that a custom color returned
    /// in this function will be actually applied, it's up to CarPlay.
    /// - Parameters:
    ///   - carPlayManager: The ``CarPlayManager`` object.
    ///   - style: A default `UIUserInterfaceStyle` generated by the system.
    /// - Returns: A `UIColor` which will be used to update `CPMapTemplate.guidanceBackgroundColor`.
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        guidanceBackgroundColorFor style: UIUserInterfaceStyle
    ) -> UIColor?

    @_spi(MapboxInternal)
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didSetup navigationMapView: NavigationMapView
    )

    @_spi(MapboxInternal)
    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        in carPlayTemplate: CPMapTemplate,
        for activity: CarPlayActivity,
        cameraState: NavigationCameraState
    ) -> [CPBarButton]?
}

extension CarPlayManagerDelegate {
    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        in carPlayTemplate: CPTemplate,
        for activity: CarPlayActivity
    ) -> [CPBarButton]? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        in carPlayTemplate: CPMapTemplate,
        for activity: CarPlayActivity
    ) -> [CPBarButton]? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        in carPlayTemplate: CPTemplate,
        for activity: CarPlayActivity
    ) -> [CPBarButton]? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        in carPlayTemplate: CPMapTemplate,
        for activity: CarPlayActivity
    ) -> [CPBarButton]? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        mapButtonsCompatibleWith traitCollection: UITraitCollection,
        in carPlayTemplate: CPTemplate,
        for activity: CarPlayActivity
    ) -> [CPMapButton]? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didFailToFetchRouteBetween waypoints: [Waypoint]?,
        options: RouteOptions,
        error: Error
    ) -> CPNavigationAlert? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        willPreview trip: CPTrip
    ) -> CPTrip {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return trip
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        willPreview trip: CPTrip,
        with previewTextConfiguration: CPTripPreviewTextConfiguration
    )
    -> CPTripPreviewTextConfiguration {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return previewTextConfiguration
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        selectedPreviewFor trip: CPTrip,
        using routeChoice: CPRouteChoice
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManagerWillCancelPreview(
        _ carPlayManager: CarPlayManager,
        configuration: inout CarPlayManagerCancelPreviewConfiguration
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManagerDidCancelPreview(_ carPlayManager: CarPlayManager) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManagerDidBeginNavigation(_ carPlayManager: CarPlayManager) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManagerWillEndNavigation(
        _ carPlayManager: CarPlayManager,
        byCanceling canceled: Bool
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManagerDidEndNavigation(
        _ carPlayManager: CarPlayManager,
        byCanceling canceled: Bool
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        shouldPresentArrivalUIFor waypoint: Waypoint
    ) -> Bool {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return false
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManagerShouldDisableIdleTimer(_ carPlayManager: CarPlayManager) -> Bool {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return true
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        willPresent navigationViewController: CarPlayNavigationViewController
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didPresent navigationViewController: CarPlayNavigationViewController
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didAdd finalDestinationAnnotation: PointAnnotation,
        to parentViewController: UIViewController,
        pointAnnotationManager: PointAnnotationManager
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        templateWillAppear template: CPTemplate,
        animated: Bool
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        templateDidAppear template: CPTemplate,
        animated: Bool
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        templateWillDisappear template: CPTemplate,
        animated: Bool
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        templateDidDisappear template: CPTemplate,
        animated: Bool
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        routeLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String,
        for parentViewController: UIViewController
    ) -> LineLayer? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        routeCasingLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String,
        for parentViewController: UIViewController
    ) -> LineLayer? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        routeRestrictedAreasLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String,
        for parentViewController: UIViewController
    ) -> LineLayer? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        willAdd layer: Layer,
        for parentViewController: UIViewController
    ) -> Layer? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didBeginPanGesture template: CPMapTemplate
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didEndPanGesture template: CPMapTemplate
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didShowPanningInterface template: CPMapTemplate
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        willDismissPanningInterface template: CPMapTemplate
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didDismissPanningInterface template: CPMapTemplate
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        shouldShowNotificationFor maneuver: CPManeuver,
        in mapTemplate: CPMapTemplate
    ) -> Bool {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return false
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        shouldShowNotificationFor navigationAlert: CPNavigationAlert,
        in mapTemplate: CPMapTemplate
    ) -> Bool {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return false
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        shouldUpdateNotificationFor maneuver: CPManeuver,
        with travelEstimates: CPTravelEstimates,
        in mapTemplate: CPMapTemplate
    ) -> Bool {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return false
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        shapeFor waypoints: [Waypoint],
        legIndex: Int
    ) -> FeatureCollection? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        guidanceBackgroundColorFor style: UIUserInterfaceStyle
    ) -> UIColor? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .debug)
        return nil
    }

    @_spi(MapboxInternal)
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didSetup navigationMapView: NavigationMapView
    ) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .debug)
    }

    @_spi(MapboxInternal)
    public func carPlayManager(
        _ carPlayManager: CarPlayManager,
        leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        in carPlayTemplate: CPMapTemplate,
        for activity: CarPlayActivity,
        cameraState: NavigationCameraState
    ) -> [CPBarButton]? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self, level: .debug)
        return nil
    }
}

/// A struct that defines the configuration of the cancel preview action in CarPlay.
public struct CarPlayManagerCancelPreviewConfiguration {
    /// Whether or not to pop to the root template when cancelling the preview.
    public var popToRoot: Bool = true

    init() {}
}
