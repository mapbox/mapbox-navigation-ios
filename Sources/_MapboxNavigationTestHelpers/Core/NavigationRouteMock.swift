import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private

extension NavigationRoute {
    public static func mock(
        route: Route = .mock(),
        routeId: RouteId = .mock(),
        nativeRoute: RouteInterface? = nil,
        directionsOptionsType: DirectionsOptions.Type = NavigationRouteOptions.self
    ) -> Self {
        let nativeRoute = nativeRoute ?? RouteInterfaceMock(route: route)
        let requestOptions = nativeRoute.getResponseOptions(directionsOptionsType)!
        return self.init(route: route, nativeRoute: nativeRoute, requestOptions: requestOptions)
    }
}
