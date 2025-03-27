@preconcurrency import MapboxNavigationNative

public class RoutesDataMock: RoutesData {
    public init() {}

    public func primaryRoute() -> any RouteInterface {
        RouteInterfaceMock()
    }

    public func alternativeRoutes() -> [RouteAlternative] {
        []
    }
}
