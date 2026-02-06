import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private
import Turf

extension AlternativeRoute {
    public static func mock(
        mainRoute: Route = .mock(),
        alternativeRoute: Route = .mock(shape: .mock(delta: (0.01, -0.01))),
        nativeRouteAlternative: RouteAlternative? = nil,
        requestOptions: ResponseOptions? = nil,
        routeIndex: Int = 0
    ) -> Self {
        let nativeAlternative = nativeRouteAlternative ?? .mock(route: alternativeRoute, routeIndex: routeIndex)
        let urlString = nativeAlternative.route.getRequestUri()
        let requestOptions = requestOptions ?? .mock(routeOptions: .mock(string: urlString))
        return self.init(
            mainRoute: mainRoute,
            alternativeRoute: alternativeRoute,
            nativeRouteAlternative: nativeAlternative,
            requestOptions: requestOptions
        )!
    }
}

extension RouteAlternative {
    public static func mock(route: Route, routeIndex: Int = 0) -> Self {
        .mock(route: RouteInterfaceMock(route: route, routeIndex: routeIndex))
    }

    public static func mock(
        id: UInt32 = 0,
        route: RouteInterface = RouteInterfaceMock(),
        mainRouteFork: RouteIntersection = .mock(),
        alternativeRouteFork: RouteIntersection = .mock(),
        infoFromFork: AlternativeRouteInfo = .mock(),
        infoFromStart: AlternativeRouteInfo = .mock(),
        isNew: Bool = true
    ) -> Self {
        self.init(
            id: id,
            route: route,
            mainRouteFork: mainRouteFork,
            alternativeRouteFork: alternativeRouteFork,
            infoFromFork: infoFromFork,
            infoFromStart: infoFromStart,
            isNew: isNew
        )
    }
}

extension RouteIntersection {
    public static func mock(
        location: CLLocationCoordinate2D = .init(latitude: 1, longitude: 2),
        geometryIndex: UInt32 = 0,
        segmentIndex: UInt32 = 0,
        legIndex: UInt32 = 0
    ) -> Self {
        self.init(
            location: location,
            geometryIndex: geometryIndex,
            segmentIndex: segmentIndex,
            legIndex: legIndex
        )
    }
}

extension AlternativeRouteInfo {
    public static func mock(distance: Double = 1000, duration: Double = 100) -> Self {
        self.init(distance: distance, duration: duration)
    }
}
