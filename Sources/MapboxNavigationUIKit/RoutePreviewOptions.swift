import MapboxDirections
import MapboxNavigationCore

/// Customization options for the routes(s) preview using ``RoutePreviewViewController`` banner.
public struct RoutePreviewOptions {
    /// `NavigationRoutes` object, that contains main and alternative routes, details about which
    /// will be presented.
    public let navigationRoutes: NavigationRoutes

    /// The route id within the ``RoutePreviewOptions/navigationRoutes`` object.
    /// The id is used to retrive and display details about the specific route.
    public let routeId: RouteId

    /// Initializes a `RoutePreviewOptions` struct.
    ///
    /// - Parameters:
    ///   - routeResponse: `NavigationRoutes` object, that contains main and alternative routes,
    ///     details about which will be presented.
    ///   - routeId: The route id within the ``RoutePreviewOptions/navigationRoutes`` object.
    ///     The id is used to retrive and display details about the specific route.
    public init(navigationRoutes: NavigationRoutes, routeId: RouteId) {
        self.navigationRoutes = navigationRoutes
        self.routeId = routeId
    }
}
