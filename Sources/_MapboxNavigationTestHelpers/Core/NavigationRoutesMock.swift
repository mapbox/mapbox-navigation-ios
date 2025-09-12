import MapboxDirections
@testable import MapboxNavigationCore
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

    public init(routesData: RoutesData) async throws {
        let routeOptions = NavigationRouteOptions.mock(nativeRoute: routesData.primaryRoute())
        try await self.init(routesData: routesData, options: .route(routeOptions))
    }
}
