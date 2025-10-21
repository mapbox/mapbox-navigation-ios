import XCTest
import CoreLocation
import MapboxDirections
import Turf
import TestHelper
@testable import MapboxCoreNavigation
import OHHTTPStubs

class RouteRefreshIntegrationTests: TestCase {
    var navigation: MapboxNavigationService!

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
        navigation = nil
        super.tearDown()
    }

    func testRouteRefreshWithDefaultDrivingTrafficProfile() {
        RouteControllerProactiveReroutingInterval = 2
        let indexedRouteResponse = RouteResponse.mockedIndexRouteResponse
        let locationManager = ReplayLocationManager(
            locations: RouteResponse.mockedRoute.simulationLocations
        )

        locationManager.speedMultiplier = 1
        navigation = MapboxNavigationService(
            indexedRouteResponse: indexedRouteResponse,
            customRoutingProvider: MapboxRoutingProvider(.online),
            credentials: Fixture.credentials,
            locationSource: locationManager,
            simulating: .never
        )
        navigation.router.refreshesRoute = true

        expectation(forNotification: .routeControllerProgressDidChange, object: navigation.router) { (notification) -> Bool in
            guard
                let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
            else {
                return false
            }

            guard
                let location = notification.userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation
            else {
                return false
            }

            print(">>>> prog \(location.coordinate)")
            return true
        }

        expectation(forNotification: .routeControllerDidRefreshRoute, object: navigation.router) { (notification) -> Bool in
            print(">>>> refr")
            return true
        }

        expectation(forNotification: .routeControllerDidUpdateAlternatives, object: navigation.router) { (notification) -> Bool in
            print(">>>> alte")
            return true
        }

        navigation.start()
        locationManager.startUpdatingLocation()
        waitForExpectations(timeout: 100) { XCTAssertNil($0) }
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
        _ profile: ProfileIdentifier = .automobileAvoidingTraffic
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
    static var mockedRoute: Route {
        mockedResponse.routes![0]
    }

    static var mockedResponse: RouteResponse {
        Fixture.routeResponse(
            from: "profile-route-original",
            options: NavigationRouteOptions.mockedOptions()
        )
    }

    static var mockedIndexRouteResponse: IndexedRouteResponse {
        IndexedRouteResponse(routeResponse: mockedResponse, routeIndex: 0)
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
