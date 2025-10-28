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
        MapboxRoutingProvider.__testRoutesStub = nil
        super.tearDown()
    }

    func testRouteRefreshWithDefaultDrivingTrafficProfile() {
        simulateOnRoute(with: .automobileAvoidingTraffic, shouldRefresh: true)
    }

    func testRouteRefreshWithCustomDrivingTrafficProfile() {
        simulateOnRoute(with: .custom, shouldRefresh: true)
    }

    func testRouteRefreshWithWalkingProfile() {
        simulateOnRoute(with: .walking, shouldRefresh: false)
    }

    func testReRouteDefaultParametersDefaultDrivingTrafficProfile() {
        simulateOffRoute(
            with: .mockedOptions(.automobileAvoidingTraffic),
            expectationKey: "RerouteDefaultParametersDefaultProfile") { options in
                XCTAssert(options.profileIdentifier == .automobileAvoidingTraffic)
            }
    }

    func testReRouteCustomParametersCustomDrivingTrafficProfile() {
        simulateOffRoute(
            with: .mockedCustomOptions(.custom),
            expectationKey: "RerouteCustomParametersDefaultProfile") { options in
                let customOptions = options as! CustomRouteOptions
                XCTAssert(customOptions.profileIdentifier == .custom)
                XCTAssert(customOptions.urlQueryItems.contains(.customItem))
            }
    }

    func testReRouteCustomParametersDefaultDrivingTrafficProfile() {
        simulateOffRoute(
            with: .mockedCustomOptions(.automobileAvoidingTraffic),
            expectationKey: "RerouteCustomParametersCustomProfile") { options in
                let customOptions = options as! CustomRouteOptions
                XCTAssert(customOptions.profileIdentifier == .automobileAvoidingTraffic)
                XCTAssert(customOptions.urlQueryItems.contains(.customItem))
            }
    }

    private func simulateOnRoute(with profile: ProfileIdentifier, shouldRefresh: Bool = true) {
        let (locationManager, navigation) = navigatorAndLocationManager(with: profile)
        let refreshExpectation = expectation(
            forNotification: .routeControllerDidRefreshRoute,
            object: navigation.router
        ) { (notification) -> Bool in
            return true
        }

        refreshExpectation.isInverted = !shouldRefresh

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

    private func simulateOffRoute(
        with options: NavigationRouteOptions,
        expectationKey: String,
        validation: @escaping (NavigationRouteOptions) -> Void
    ) {
        let response = RouteResponse.mockedIndexRouteResponse(options: options)
        let simulationLocations = response.routeResponse.routes![0].simulationOffRouteLocations
        let (locationManager, navigation) = navigatorAndLocationManager(
            with: response,
            simulationLocations: simulationLocations
        )

        let expection = expectation(description: expectationKey)
        MapboxRoutingProvider.__testRoutesStub = { (options, completionHandler) in
            validation(options as! NavigationRouteOptions)
            expection.fulfill()
            return nil
        }

        navigation.start()
        locationManager.startUpdatingLocation()
        waitForExpectations(timeout: .defaultDelay) { XCTAssertNil($0) }
    }

    private func navigatorAndLocationManager(
        with profile: ProfileIdentifier,
    ) -> (ReplayLocationManager, MapboxNavigationService) {
        RouteControllerProactiveReroutingInterval = 2

        let indexedRouteResponse = RouteResponse.mockedIndexRouteResponse(profile: profile)
        let locationManager = ReplayLocationManager(
            locations: indexedRouteResponse.routeResponse.routes![0].simulationOnRouteLocations
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

    private func navigatorAndLocationManager(
        with indexedRouteResponse: IndexedRouteResponse,
        simulationLocations: [CLLocation]
    ) -> (ReplayLocationManager, MapboxNavigationService) {
        RouteControllerProactiveReroutingInterval = 2
        let locationManager = ReplayLocationManager(locations: simulationLocations)
        locationManager.speedMultiplier = 5
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
    var simulationOnRouteLocations: [CLLocation] {
        shape!
            .coordinates
            .map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
            .shiftedToPresent()
            .qualified()
    }

    var simulationOffRouteLocations: [CLLocation] {
        let stepCoordiantes = legs[0].steps[0].shape!.coordinates
        let stepFirstLocation = stepCoordiantes.first!
        let stepLastLocation = stepCoordiantes.last!
        let stepDirection = stepFirstLocation.direction(to: stepLastLocation)

        let offRouteCoordiantes =  [20, 30, 40].map { stepLastLocation.coordinate(at: $0, facing: stepDirection) }
        let coordinates = stepCoordiantes + offRouteCoordiantes
        return coordinates
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

    static func mockedCustomOptions(
        _ profile: ProfileIdentifier
    ) -> NavigationRouteOptions {
        CustomRouteOptions(
            waypoints: [
                .init(coordinate: .origin),
                .init(coordinate: .destiantion),
            ],
            profileIdentifier: profile,
            customParameters: [.customItem]
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

    static func mockedResponse(options: NavigationRouteOptions) -> RouteResponse {
        Fixture.routeResponse(
            from: "profile-route-original",
            options: options
        )
    }

    static func mockedIndexRouteResponse(
        options: NavigationRouteOptions
    ) -> IndexedRouteResponse {
        IndexedRouteResponse(
            routeResponse: mockedResponse(options: options),
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

fileprivate extension URLQueryItem {
    static let customItem: URLQueryItem = .init(name: "foo", value: "bar")
}

fileprivate final class CustomRouteOptions: NavigationRouteOptions {
    var customParameters: [URLQueryItem]

    init(
        waypoints: [Waypoint],
        profileIdentifier: ProfileIdentifier? = nil,
        customParameters: [URLQueryItem] = []
    ) {
        self.customParameters = customParameters

        super.init(waypoints: waypoints, profileIdentifier: profileIdentifier)
    }

    required init(
        waypoints: [Waypoint],
        profileIdentifier: ProfileIdentifier? = nil,
        queryItems: [URLQueryItem]? = nil
    ) {
        self.customParameters = []
        super.init(
            waypoints: waypoints,
            profileIdentifier: profileIdentifier,
            queryItems: queryItems
        )
    }

    required init(from decoder: any Decoder) throws {
        self.customParameters = []
        try super.init(from: decoder)
    }

    override var urlQueryItems: [URLQueryItem] {
        var combined = super.urlQueryItems
        combined.append(contentsOf: customParameters)
        return combined
    }
}
