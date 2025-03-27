import _MapboxNavigationTestHelpers
import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
import XCTest

final class MapboxRoutingProviderTests: TestCase {
    override func setUp() {
        super.setUp()
        Environment.switchEnvironment(to: .test)
    }

    override func tearDown() {
        Environment.switchEnvironment(to: .live)
        super.tearDown()
    }

    private var waypoint1 = Waypoint(location: CLLocation(latitude: 9.519172, longitude: 47.210823))
    private var waypoint2 = Waypoint(location: CLLocation(latitude: 9.619172, longitude: 47.310823))

    @MainActor
    func testCalculateRouteWithRouteOptions() {
        let callExpectation = expectation(description: "getRouteForDirectionsUri expectation")

        var routerClient = RouterClient.testValue
        routerClient.getRouteForDirectionsUri = {
            _, _, _, _ in
            callExpectation.fulfill()
            return 12345
        }
        routerClient.getRouteMapMatchedFor = { _, _, _ in
            XCTFail("getRouteMapMatchedFor should not be called")
            return 0
        }
        let routerProviderClient = RouterProviderClient.value(with: routerClient)
        Environment.set(\.routerProviderClient, routerProviderClient)

        let navigationProvider = MapboxNavigationProvider(coreConfig: coreConfig)
        let routingProvider = navigationProvider.routingProvider()

        let routeOptions = RouteOptions(
            waypoints: [waypoint1, waypoint2],
            profileIdentifier: .automobileAvoidingTraffic
        )

        _ = routingProvider.calculateRoutes(options: routeOptions)

        wait(for: [callExpectation], timeout: 0.1)
    }

    @MainActor
    func testCalculateRouteWithMatchOptions() {
        let callExpectation = expectation(description: "getRouteMapMatchedFor expectation")

        var routerClient = RouterClient.testValue
        routerClient.getRouteMapMatchedFor = { _, _, _ in
            callExpectation.fulfill()
            return 54321
        }
        routerClient.getRouteForDirectionsUri = {
            _, _, _, _ in
            XCTFail("getRouteForDirectionsUri should not be called")
            return 0
        }
        let routerProviderClient = RouterProviderClient.value(with: routerClient)
        Environment.set(\.routerProviderClient, routerProviderClient)

        let navigationProvider = MapboxNavigationProvider(coreConfig: coreConfig)
        let routingProvider = navigationProvider.routingProvider()

        let matchOptions = MatchOptions(
            waypoints: [waypoint1, waypoint2],
            profileIdentifier: .automobileAvoidingTraffic
        )

        _ = routingProvider.calculateRoutes(options: matchOptions)

        wait(for: [callExpectation], timeout: 0.1)
    }
}
