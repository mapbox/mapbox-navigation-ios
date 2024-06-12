import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative

extension NavigationRoute {
    public static func mock(
        route: Route = .mock(),
        routeId: RouteId = .mock(),
        nativeRoute: RouteInterface = RouteInterfaceMock()
    ) -> Self {
        self.init(route: route, nativeRoute: nativeRoute)
    }
}
