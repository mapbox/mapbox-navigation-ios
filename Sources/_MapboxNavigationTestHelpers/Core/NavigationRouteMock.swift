import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative

extension NavigationRoute {
    public static func mock(
        route: Route = .mock(),
        routeId: RouteId = .mock(),
        nativeRoute: RouteInterface? = nil
    ) -> Self {
        let nativeRoute = nativeRoute ?? RouteInterfaceMock(route: route)
        return self.init(route: route, nativeRoute: nativeRoute)
    }
}
