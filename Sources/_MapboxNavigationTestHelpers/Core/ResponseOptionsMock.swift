import Foundation
import MapboxDirections
import MapboxNavigationCore
import MapboxNavigationNative_Private

extension RouteOptions {
    public static func mock(string: String = RouteInterfaceMock.realRequestUri) -> RouteOptions {
        RouteOptions(url: URL(string: string)!)!
    }

    public static func mock(nativeRoute: any RouteInterface) -> RouteOptions {
        RouteOptions(url: URL(string: nativeRoute.getRequestUri())!)!
    }
}

extension ResponseOptions {
    public static func mock(routeOptions: RouteOptions = RouteOptions.mock()) -> Self {
        .route(routeOptions)
    }
}
