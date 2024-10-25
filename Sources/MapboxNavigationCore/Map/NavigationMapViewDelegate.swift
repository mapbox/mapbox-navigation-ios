import MapboxDirections
import MapboxMaps
import Turf
import UIKit

/// The ``NavigationMapViewDelegate`` provides methods for responding to events triggered by the ``NavigationMapView``.
@MainActor
public protocol NavigationMapViewDelegate: AnyObject, UnimplementedLogging {
    /// Tells the receiver that the user has selected an alternative route by interacting with the map view.
    /// - Parameters:
    ///   - navigationMapView: The ``NavigationMapView``.
    ///   - alternativeRoute: The selected alternative route.
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect alternativeRoute: AlternativeRoute)

    /// Tells the receiver that the user has tapped on a POI.
    /// - Parameters:
    ///   - navigationMapView: The ``NavigationMapView``.
    ///   - mapPoint: A selected ``MapPoint``.
    func navigationMapView(_ navigationMapView: NavigationMapView, userDidTap mapPoint: MapPoint)

    /// Tells the receiver that the user has long tapped on a POI.
    /// - Parameters:
    ///   - navigationMapView: The ``NavigationMapView``.
    ///   - mapPoint: A selected ``MapPoint``.
    func navigationMapView(_ navigationMapView: NavigationMapView, userDidLongTap mapPoint: MapPoint)

    /// Tells the receiver that the user has started interacting with the map view, e.g. with panning gesture.
    /// - Parameter navigationMapView: The ``NavigationMapView``.
    func navigationMapViewUserDidStartInteraction(_ navigationMapView: NavigationMapView)

    /// Tells the receiver that the user has stopped interacting with the map view.
    /// - Parameter navigationMapView: The ``NavigationMapView``.
    func navigationMapViewUserDidEndInteraction(_ navigationMapView: NavigationMapView)

    /// Tells the receiver that the camera changed its state.
    /// - Parameters:
    ///   - navigationMapView: The ``NavigationMapView`` object.
    ///   - cameraState: A new camera state.
    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        didChangeCameraState cameraState: NavigationCameraState
    )

    /// Tells the receiver that a waypoint was selected.
    /// - Parameters:
    ///   - navigationMapView: The ``NavigationMapView``.
    ///   - waypoint: The waypoint that was selected.
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect waypoint: Waypoint)

    /// Tells the receiver that the final destination `PointAnnotation` was added to the ``NavigationMapView``.
    /// - Parameters:
    ///   - navigationMapView: The ``NavigationMapView`` object.
    ///   - finalDestinationAnnotation: The point annotation that was added to the map view.
    ///   - pointAnnotationManager: The object that manages the point annotation in the map view.
    @available(
        *,
        deprecated,
        message: "This method is deprecated and should no longer be used, as the final destination annotation is no longer added to the map."
    )
    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        didAdd finalDestinationAnnotation: PointAnnotation,
        pointAnnotationManager: PointAnnotationManager
    )

    /// Tells the reciever that ``NavigationMapView`` has updated the displayed ``NavigationRoutes`` for the active
    /// guidance.
    /// - Parameters:
    ///   - navigationMapView: The ``NavigationMapView`` object.
    ///   - navigationRoutes: New displayed ``NavigationRoutes`` object.
    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        didAddRedrawActiveGuidanceRoutes navigationRoutes: NavigationRoutes
    )

    // MARK: Supplying Waypoint(s) Data

    /// Asks the receiver to return a `CircleLayer` for waypoints, given an identifier and source.
    /// This method is invoked any time waypoints are added or shown.
    /// - Parameters:
    ///   - navigationMapView: The ``NavigationMapView`` object.
    ///   - identifier: The `CircleLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the waypoint data that this method would style.
    /// - Returns: A `CircleLayer` that the map applies to all waypoints.
    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer?

    /// Asks the receiver to return a `SymbolLayer` for intermediate waypoint symbols, given an identifier and source.
    /// This method is invoked any time intermediate waypoints are added or shown.
    /// - Parameters:
    ///   - navigationMapView: The ``NavigationMapView`` object.
    ///   - identifier: The `SymbolLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the waypoint data that this method would style.
    /// - Returns: A `SymbolLayer` that the map applies to all waypoint symbols.
    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer?

    /// Asks the receiver to return a `FeatureCollection` that describes the geometry of waypoints.
    /// - Parameters:
    ///   - navigationMapView: The ``NavigationMapView`` object.
    ///   - waypoints: The waypoints to be displayed on the map.
    ///   - legIndex: The index of the current leg during navigation.
    /// - Returns: Optionally, a `FeatureCollection` that defines the shape of the waypoint, or `nil` to use default
    /// behavior.
    func navigationMapView(_ navigationMapView: NavigationMapView, shapeFor waypoints: [Waypoint], legIndex: Int)
        -> FeatureCollection?

    // MARK: Supplying Route Line(s) Data

    /// Asks the receiver to return a `LineLayer` for the route line, given a layer identifier and a source identifier.
    /// This method is invoked when the map view loads and any time routes are added.
    /// - Parameters:
    ///   - navigationMapView: The ``NavigationMapView`` object.
    ///   - identifier: The `LineLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
    /// - Returns: A `LineLayer` that is applied to the route line.
    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        routeLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer?

    /// Asks the receiver to return a `LineLayer` for the casing layer that surrounds route line, given a layer
    /// identifier and a source identifier. This method is invoked when the map view loads and any time routes are
    /// added.
    /// - Parameters:
    ///   - navigationMapView: The ``NavigationMapView`` object.
    ///   - identifier: The `LineLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
    /// - Returns: A `LineLayer` that is applied as a casing around the route line.
    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        routeCasingLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer?

    /// Asks the receiver to return a `LineLayer` for highlighting restricted areas portions of the route, given a layer
    /// identifier and a source identifier. This method is invoked when
    /// ``NavigationMapView/showsRestrictedAreasOnRoute`` is enabled, the map view loads and any time routes are added.
    /// - Parameters:
    ///   - navigationMapView: The ``NavigationMapView`` object.
    ///   - identifier: The `LineLayer` identifier.
    ///   - sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
    /// - Returns: A `LineLayer` that is applied as restricted areas on the route line.
    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        routeRestrictedAreasLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer?

    /// Asks the receiver to adjust the default layer which will be added to the map view and return a `Layer`.
    /// This method is invoked when the map view loads and any time a layer will be added.
    /// - Parameters:
    ///   - navigationMapView: The ``NavigationMapView`` object.
    ///   - layer: A default `Layer` generated by the navigationMapView.
    /// - Returns: An adjusted `Layer` that will be added to the map view by the SDK.
    func navigationMapView(_ navigationMapView: NavigationMapView, willAdd layer: Layer) -> Layer?
}

extension NavigationMapViewDelegate {
    /// ``UnimplementedLogging`` prints a warning to standard output the first time this method is called.
    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        routeLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }

    /// ``UnimplementedLogging`` prints a warning to standard output the first time this method is called.
    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        routeCasingLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }

    /// ``UnimplementedLogging`` prints a warning to standard output the first time this method is called.
    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        routeRestrictedAreasLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }

    /// ``UnimplementedLogging`` prints a warning to standard output the first time this method is called.
    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        didSelect alternativeRoute: AlternativeRoute
    ) {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
    }

    /// ``UnimplementedLogging`` prints a warning to standard output the first time this method is called.
    public func navigationMapView(_ navigationMapView: NavigationMapView, userDidTap mapPoint: MapPoint) {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
    }

    /// ``UnimplementedLogging`` prints a warning to standard output the first time this method is called.
    public func navigationMapView(_ navigationMapView: NavigationMapView, userDidLongTap mapPoint: MapPoint) {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
    }

    /// ``UnimplementedLogging`` prints a warning to standard output the first time this method is called.
    public func navigationMapViewUserDidStartInteraction(_ navigationMapView: NavigationMapView) {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
    }

    /// ``UnimplementedLogging`` prints a warning to standard output the first time this method is called.
    public func navigationMapViewUserDidEndInteraction(_ navigationMapView: NavigationMapView) {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
    }

    /// ``UnimplementedLogging`` prints a warning to standard output the first time this method is called.
    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        didChangeCameraState cameraState: NavigationCameraState
    ) {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
    }

    public func navigationMapView(_ navigationMapView: NavigationMapView, didSelect waypoint: Waypoint) {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
    }

    /// ``UnimplementedLogging`` prints a warning to standard output the first time this method is called.
    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        didAdd finalDestinationAnnotation: PointAnnotation,
        pointAnnotationManager: PointAnnotationManager
    ) {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
    }

    /// ``UnimplementedLogging`` prints a warning to standard output the first time this method is called.
    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        didAddRedrawActiveGuidanceRoutes navigationRoutes: NavigationRoutes
    ) {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
    }

    /// ``UnimplementedLogging`` prints a warning to standard output the first time this method is called.
    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        shapeFor waypoints: [Waypoint],
        legIndex: Int
    ) -> FeatureCollection? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }

    /// ``UnimplementedLogging`` prints a warning to standard output the first time this method is called.
    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }

    /// ``UnimplementedLogging`` prints a warning to standard output the first time this method is called.
    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }

    /// ``UnimplementedLogging`` prints a warning to standard output the first time this method is called.
    public func navigationMapView(_ navigationMapView: NavigationMapView, willAdd layer: Layer) -> Layer? {
        logUnimplemented(protocolType: NavigationMapViewDelegate.self, level: .debug)
        return nil
    }
}
