import XCTest
import CoreLocation
import MapboxDirections
import Turf
import TestHelper
import MapboxNavigationNative
@testable import MapboxCoreNavigation

let jsonFileName = "routeWithInstructions"
let jsonFileNameEmptyDistance = "routeWithNoDistance"
var routeOptions: NavigationRouteOptions {
    let from = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
    let to = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
    return NavigationRouteOptions(waypoints: [from, to])
}
let response = Fixture.routeResponse(from: jsonFileName, options: routeOptions)
let indexedRouteResponse = IndexedRouteResponse(routeResponse: response, routeIndex: 0)
let route: Route = {
    return Fixture.route(from: jsonFileName, options: routeOptions)
}()
let routeWithNoDistance: Route = {
    return Fixture.route(from: jsonFileNameEmptyDistance, options: routeOptions)
}()

let waitForInterval: TimeInterval = 5
