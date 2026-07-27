import MapboxNavigationNative

@_spi(ExperimentalMapboxAPI)
extension NavigationRoutes {
    public var navSdkRouteInterfaces: [RouteInterface] {
        [mainRoute.nativeRouteInterface] + alternativeRoutes.map(\.nativeRoute)
    }

    public var mainRouteInterface: RouteInterface {
        mainRoute.nativeRouteInterface
    }

    public var alternativeRouteInterfaces: [RouteInterface] {
        alternativeRoutes.map(\.nativeRoute)
    }
}
