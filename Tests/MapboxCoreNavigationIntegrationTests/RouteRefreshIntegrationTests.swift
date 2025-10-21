import XCTest
import CoreLocation
import MapboxDirections
import Turf
import TestHelper
@testable import MapboxCoreNavigation
import OHHTTPStubs

class RouteRefreshIntegrationTests: TestCase {
    override func setUp() {
        super.setUp()
        HTTPStubs.stubRequests(
            passingTest: { request -> Bool in
                request.url?.absoluteString.contains("directions-refresh") ?? false
            }) { request -> HTTPStubsResponse in
                HTTPStubsResponse(
                    data: Fixture.JSONFromFileNamed(name: "profile-route-refresh"),
                    statusCode: 200,
                    headers: ["Content-Type":"application/json"]
                )
        }
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testRouteRefreshWithDefaultDrivingTrafficProfile() {
        simulateRoute(with: .automobileAvoidingTraffic, shouldRefresh: true)
    }

    func testRouteRefreshWithCustomDrivingTrafficProfile() {
        simulateRoute(with: .custom, shouldRefresh: true)
    }

    func testRouteRefreshWithWalkingProfile() {
        simulateRoute(with: .walking, shouldRefresh: false)
    }

    private func simulateRoute(with profile: ProfileIdentifier, shouldRefresh: Bool = true) {
        let (locationManager, navigation) = navigatorAndLocationManager(with: profile)
        let refreshExpectation = expectation(
            forNotification: .routeControllerDidRefreshRoute,
            object: navigation.router
        ) { (notification) -> Bool in
            return true
        }

        refreshExpectation.isInverted = shouldRefresh

        expectation(
            forNotification: .routeControllerDidUpdateAlternatives,
            object: navigation.router
        ) { (notification) -> Bool in
            return true
        }

        navigation.start()
        locationManager.startUpdatingLocation()
        waitForExpectations(timeout: .defaultDelay) { XCTAssertNil($0) }
    }

    private func navigatorAndLocationManager(
        with profile: ProfileIdentifier
    ) -> (ReplayLocationManager, MapboxNavigationService) {
        RouteControllerProactiveReroutingInterval = 2

        let indexedRouteResponse = RouteResponse.mockedIndexRouteResponse(profile: profile)
        let locationManager = ReplayLocationManager(
            locations: indexedRouteResponse.routeResponse.routes![0].simulationLocations
        )

        locationManager.speedMultiplier = 1
        let navigation = MapboxNavigationService(
            indexedRouteResponse: indexedRouteResponse,
            customRoutingProvider: MapboxRoutingProvider(.online),
            credentials: Fixture.credentials,
            locationSource: locationManager,
            simulating: .never
        )
        return (locationManager, navigation)
    }
}

fileprivate extension Route {
    var simulationLocations: [CLLocation] {
        shape!
            .coordinates
            .map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
            .shiftedToPresent()
            .qualified()
    }
}

fileprivate extension NavigationRouteOptions {
    static func mockedOptions(
        _ profile: ProfileIdentifier
    ) -> NavigationRouteOptions {
        NavigationRouteOptions(
            coordinates: [
                .origin,
                .destiantion
            ],
            profileIdentifier: profile
        )
    }
}

fileprivate extension RouteResponse {
    static func mockedResponse(profile: ProfileIdentifier) -> RouteResponse {
        Fixture.routeResponse(
            from: "profile-route-original",
            options: NavigationRouteOptions.mockedOptions(profile)
        )
    }

    static func mockedIndexRouteResponse(
        profile: ProfileIdentifier
    ) -> IndexedRouteResponse {
        IndexedRouteResponse(
            routeResponse: mockedResponse(profile: profile),
            routeIndex: 0
        )
    }
}

fileprivate extension CLLocationCoordinate2D {
    static var origin: CLLocationCoordinate2D {
        .init(latitude: -73.98778274913309, longitude: 40.76050975068355)
    }

    static var destiantion: CLLocationCoordinate2D {
        .init(latitude: -73.98039053825985, longitude: 40.75988085727627)
    }
}

fileprivate extension TimeInterval {
    static let defaultDelay: Self = 5
}

fileprivate extension ProfileIdentifier {
    static let custom: ProfileIdentifier = .init(rawValue: "custom/driving-traffic")
}
