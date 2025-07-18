import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private
import Turf

extension AlternativeRoute {
    public static func mock(
        mainRoute: Route = .mock(
            shape: mockShape
        ),
        alternativeRoute: Route = .mock(),
        nativeRouteAlternative: RouteAlternative? = nil
    ) -> Self {
        let nativeAlternative = nativeRouteAlternative ?? .mock(route: alternativeRoute)
        return self.init(
            mainRoute: mainRoute,
            alternativeRoute: alternativeRoute,
            nativeRouteAlternative: nativeAlternative
        )!
    }

    public static var mockShape: LineString {
        .init(
            [CLLocationCoordinate2D](
                repeating: .init(
                    latitude: 1,
                    longitude: 2
                ),
                count: 4
            )
        )
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
