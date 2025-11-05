import MapboxDirections
@_spi(MapboxInternal) @testable import MapboxNavigationCore
import MapboxNavigationNative_Private

extension NavigationRoutes {
    public static func mock(
        mainRoute: NavigationRoute = .mock(),
        alternativeRoutes: [AlternativeRoute] = [],
        waypoints: [MapboxDirections.Waypoint] = []
    ) async -> Self {
        await self.init(
            mainRoute: mainRoute,
            alternativeRoutes: alternativeRoutes,
            waypoints: waypoints
        )
    }

    static func mock(
        routeResponse: RouteResponse,
        routeIndex: Int = 0,
        responseOrigin: RouterOrigin = .online
    ) async -> NavigationRoutes? {
        try? await NavigationRoutes(
            routeResponse: routeResponse,
            routeIndex: routeIndex,
            responseOrigin: responseOrigin
        )
    }

    public init(routesData: RoutesData) async throws {
        let routeOptions = NavigationRouteOptions.mock(nativeRoute: routesData.primaryRoute())
        try await self.init(routesData: routesData, options: .route(routeOptions))
    }
}
