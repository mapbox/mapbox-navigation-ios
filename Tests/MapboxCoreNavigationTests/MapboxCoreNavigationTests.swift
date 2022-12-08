import XCTest
import CoreLocation
import MapboxDirections
import Turf
import TestHelper
@testable import MapboxCoreNavigation

let jsonFileName = "routeWithInstructions"
let jsonFileNameEmptyDistance = "routeWithNoDistance"

var routeOptions: NavigationRouteOptions {
    let from = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
    let to = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
    return NavigationRouteOptions(waypoints: [from, to])
}

func makeRouteResponse() -> RouteResponse {
    return Fixture.routeResponse(from: jsonFileName, options: routeOptions)
}

func makeRoute() -> Route {
    return Fixture.route(from: jsonFileName, options: routeOptions)
}

func makeRouteWithNoDistance() -> Route {
    return Fixture.route(from: jsonFileNameEmptyDistance, options: routeOptions)
}
