@testable import _MapboxNavigationTestHelpers
import CoreLocation
import MapboxCommon_Private.MBXExpected
import MapboxDirections
import MapboxNavigationNative_Private
@_spi(MapboxInternal) @testable import MapboxNavigationCore
import XCTest

final class NavigationRoutesTests: TestCase {
    private var waypoint1 = Waypoint(location: CLLocation(latitude: 9.519172, longitude: 47.210823))
    private var waypoint2 = Waypoint(location: CLLocation(latitude: 9.619172, longitude: 47.310823))

    private lazy var routeOptions: RouteOptions = .init(
        waypoints: [waypoint1, waypoint2],
        profileIdentifier: .automobileAvoidingTraffic
    )

    private lazy var matchOptions: MatchOptions = .init(
        waypoints: [waypoint1, waypoint2],
        profileIdentifier: .automobileAvoidingTraffic
    )

    private lazy var routeResponse = RouteResponse.mock(
        bundle: .module,
        options: routeOptions,
        fileName: "routeResponse"
    )

    private lazy var mapMatchingResponse = MapMatchingResponse.mock(
        bundle: .module,
        options: matchOptions,
        fileName: "matchResponse"
    )

    override func setUp() {
        super.setUp()
        Environment.switchEnvironment(to: .test)
    }

    override func tearDown() {
        Environment.switchEnvironment(to: .live)
        super.tearDown()
    }

    func testInitWithRouterResponse() async {
        let callExpectation1 = expectation(description: "parseDirectionsResponseForResponseDataRef expectation")
        let callExpectation2 = expectation(description: "createRoutesData expectation")

        var routeParserClient = RouteParserClient.testValue
        routeParserClient.parseDirectionsResponseForResponseDataRef = { _, _, _ in
            callExpectation1.fulfill()
            return Expected<NSArray, NSString>(value: [RouteInterfaceMock()])
        }
        routeParserClient.parseMapMatchingResponseForResponseDataRef = { _, _, _ in
            XCTFail("parseMapMatchingResponseForResponseDataRef should not be called")
            return Expected<NSArray, NSString>(value: [])
        }
        routeParserClient.createRoutesData = { _, _ in
            callExpectation2.fulfill()
            return RoutesDataMock()
        }
        Environment.set(\.routeParserClient, routeParserClient)

        guard let routeResponse else {
            XCTFail("Cannot create RouteResponse")
            return
        }

        do {
            _ = try await NavigationRoutes(routeResponse: routeResponse, routeIndex: 0, responseOrigin: .online)

        } catch {
            XCTFail("Failed creating NavigationRoutes: \(error).")
            return
        }

        await fulfillment(of: [callExpectation1, callExpectation2], timeout: 0.1)
    }

    func testInitWithMapMatchingResponse() async {
        let callExpectation1 = expectation(description: "parseMapMatchingResponseForResponseDataRef expectation")
        let callExpectation2 = expectation(description: "createRoutesData expectation")

        var routeParserClient = RouteParserClient.testValue
        routeParserClient.parseMapMatchingResponseForResponseDataRef = { _, _, _ in
            callExpectation1.fulfill()
            return Expected<NSArray, NSString>(value: [RouteInterfaceMock()])
        }
        routeParserClient.parseDirectionsResponseForResponseDataRef = { _, _, _ in
            XCTFail("parseDirectionsResponseForResponseDataRef should not be called")
            return Expected<NSArray, NSString>(value: [])
        }
        routeParserClient.createRoutesData = { _, _ in
            callExpectation2.fulfill()
            return RoutesDataMock()
        }
        Environment.set(\.routeParserClient, routeParserClient)

        guard let mapMatchingResponse else {
            XCTFail("Cannot create MapMatchingResponse")
            return
        }

        do {
            _ = try await NavigationRoutes(
                mapMatchingResponse: mapMatchingResponse,
                routeIndex: 0,
                responseOrigin: .online
            )

        } catch {
            XCTFail("Failed creating NavigationRoutes: \(error).")
            return
        }

        await fulfillment(of: [callExpectation1, callExpectation2], timeout: 0.1)
    }

    func testCreateRoutesWithLessAlternatives() async throws {
        var routeParserClient = RouteParserClient.testValue

        guard let routeResponse = RouteResponse.mock(
            bundle: .module,
            options: routeOptions,
            fileName: "alternativesRouteResponse"
        ) else {
            XCTFail("Cannot create RouteResponse")
            return
        }

        let alternativeMock = RouteInterfaceMock(route: .mock(), routeIndex: 2)
        routeParserClient.parseDirectionsResponseForResponseDataRef = { responseDataRef, request, origin in
            RouteParserClient.liveValue.parseDirectionsResponseForResponseDataRef(responseDataRef, request, origin)
        }
        routeParserClient.createRoutesData = { _, _ in
            RoutesDataMock(alternativeRoutes: [.mock(route: alternativeMock)])
        }
        Environment.set(\.routeParserClient, routeParserClient)

        let navigationRoutes = try await NavigationRoutes(
            routeResponse: routeResponse,
            routeIndex: 0,
            responseOrigin: .online
        )
        XCTAssertNotNil(navigationRoutes)
        XCTAssertEqual(routeResponse.routes!.count, 3)
        XCTAssertEqual(navigationRoutes.alternativeRoutes.count, 1, "One alternative is missing")
    }

    func testCreateRoutesWithLessAlternativesIfInvalidIndex() async throws {
        var routeParserClient = RouteParserClient.testValue

        guard let routeResponse = RouteResponse.mock(
            bundle: .module,
            options: routeOptions,
            fileName: "alternativesRouteResponse"
        ) else {
            XCTFail("Cannot create RouteResponse")
            return
        }

        let alternativeMock = RouteInterfaceMock(route: .mock(), routeIndex: 10)
        routeParserClient.parseDirectionsResponseForResponseDataRef = { responseDataRef, request, origin in
            RouteParserClient.liveValue.parseDirectionsResponseForResponseDataRef(responseDataRef, request, origin)
        }
        routeParserClient.createRoutesData = { _, _ in
            RoutesDataMock(alternativeRoutes: [.mock(route: alternativeMock)])
        }
        Environment.set(\.routeParserClient, routeParserClient)

        let navigationRoutes = try await NavigationRoutes(
            routeResponse: routeResponse,
            routeIndex: 0,
            responseOrigin: .online
        )
        XCTAssertNotNil(navigationRoutes)
        XCTAssertEqual(routeResponse.routes!.count, 3)
        XCTAssertEqual(
            navigationRoutes.alternativeRoutes.count,
            0,
            "No alternatives should be created for invalid index"
        )
    }
}
