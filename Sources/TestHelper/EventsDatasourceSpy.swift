import XCTest
import CoreLocation
import MapboxDirections
@testable import MapboxCoreNavigation

final class ActiveNavigationEventsManagerDataSourceSpy: ActiveNavigationEventsManagerDataSource {
    var routeProgress: RouteProgress
    var router: Router
    var desiredAccuracy: CLLocationAccuracy = -1
    var locationManagerType: NavigationLocationManager.Type = NavigationLocationManagerSpy.self

    init() {
        let from = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
        let to = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
        let routeOptions = NavigationRouteOptions(waypoints: [from, to])
        let routeResponse = Fixture.routeResponse(from: "routeWithInstructions", options: routeOptions)
        let indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 0)
        routeProgress = RouteProgress(route: routeResponse.routes![0], options: routeOptions)
        router = RouterSpy(indexedRouteResponse: indexedRouteResponse,
                                  dataSource: RouterDataSourceSpy())
    }
}

final class PassiveNavigationEventsManagerDataSourceSpy: PassiveNavigationEventsManagerDataSource {
    var rawLocation: CLLocation? = nil
    var locationManagerType: NavigationLocationManager.Type = NavigationLocationManagerSpy.self
}
