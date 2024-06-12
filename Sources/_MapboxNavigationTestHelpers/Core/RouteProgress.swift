import Foundation
import MapboxDirections
import MapboxNavigationCore

extension RouteStepProgress {
    public static func mock(step: RouteStep = .mock()) -> Self {
        self.init(step: step)
    }
}

extension RouteLegProgress {
    public static func mock(leg: RouteLeg = .mock()) -> Self {
        self.init(leg: leg)
    }
}

extension RouteProgress {
    public static func mock(
        navigationRoutes: NavigationRoutes,
        waypoints: [Waypoint] = [],
        congestionConfiguration: CongestionRangesConfiguration = .default
    ) async -> Self {
        self.init(
            navigationRoutes: navigationRoutes,
            waypoints: waypoints,
            congestionConfiguration: congestionConfiguration
        )
    }

    public static func mock(
        mainRoute: NavigationRoute = .mock(),
        alternativeRoutes: [AlternativeRoute] = [],
        waypoints: [Waypoint] = [],
        congestionConfiguration: CongestionRangesConfiguration = .default
    ) async -> Self {
        let navigationRoutes = await NavigationRoutes.mock(mainRoute: mainRoute, alternativeRoutes: alternativeRoutes)
        return self.init(
            navigationRoutes: navigationRoutes,
            waypoints: waypoints,
            congestionConfiguration: congestionConfiguration
        )
    }
}
