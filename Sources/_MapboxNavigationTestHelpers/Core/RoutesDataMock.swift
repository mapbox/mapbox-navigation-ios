@preconcurrency import MapboxNavigationNative

public final class RoutesDataMock: RoutesData {
    let _primaryRoute: any RouteInterface
    let _alternativeRoutes: [RouteAlternative]

    public init(
        primaryRoute: any RouteInterface = RouteInterfaceMock(),
        alternativeRoutes: [RouteAlternative] = []
    ) {
        self._primaryRoute = primaryRoute
        self._alternativeRoutes = alternativeRoutes
    }

    public func primaryRoute() -> any RouteInterface {
        _primaryRoute
    }

    public func alternativeRoutes() -> [RouteAlternative] {
        _alternativeRoutes
    }
}

extension RoutesDataMock {
    public static func mock(
        primaryRoute: any RouteInterface = RouteInterfaceMock(),
        alternativeRoutes: [any RouteInterface] = []
    ) -> RoutesData {
        let nativeAlternativeRoutes = alternativeRoutes.enumerated().map { i, nativeRoute in
            return RouteAlternative(
                id: UInt32(i),
                route: nativeRoute,
                mainRouteFork: .mock(),
                alternativeRouteFork: .mock(),
                infoFromFork: .mock(),
                infoFromStart: .mock(),
                isNew: false
            )
        }
        return RoutesDataMock(primaryRoute: primaryRoute, alternativeRoutes: nativeAlternativeRoutes)
    }
}
