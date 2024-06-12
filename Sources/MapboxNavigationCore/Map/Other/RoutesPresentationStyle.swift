import MapboxMaps

/// A style that will be used when presenting routes on top of a map view by calling
/// `NavigationMapView.showcase(_:routesPresentationStyle:animated:)`.
public enum RoutesPresentationStyle {
    /// Only first route will be presented on a map view.
    case main

    /// All routes will be presented on a map view.
    ///
    /// - parameter shouldFit: If `true` geometry of all routes will be used for camera transition.
    /// If `false` geometry of only first route will be used. Defaults to `true`.
    case all(shouldFit: Bool = true)
}
