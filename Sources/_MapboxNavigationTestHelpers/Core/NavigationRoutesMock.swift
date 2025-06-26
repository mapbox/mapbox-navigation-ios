import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private

extension NavigationRoutes {
    public static func mock(
        mainRoute: NavigationRoute = .mock(),
        alternativeRoutes: [AlternativeRoute] = []
    ) async -> Self {
        await self.init(mainRoute: mainRoute, alternativeRoutes: alternativeRoutes)
    }
}
