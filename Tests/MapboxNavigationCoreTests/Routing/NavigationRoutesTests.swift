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

    func testRouteResponseNROParsing() async {
        Environment.set(\.routeParserClient, RouteParserClient.liveValue)

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
    }

    func testMapMatchingResponseNROParsing() async {
        Environment.set(\.routeParserClient, RouteParserClient.liveValue)

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
    }

    /// Each alternative is decoded from its own ``RouteInterface/toJson()`` payload, so a non-zero
    /// original response index must not cause it to be dropped.
    func testCreateRoutesKeepsAlternativesWithNonZeroRouteIndex() async throws {
        let mainRoute = Route.mock(legs: [.mock(name: "main")])
        let firstAlternative = Route.mock(legs: [.mock(name: "first-alternative")])
        let secondAlternative = Route.mock(legs: [.mock(name: "second-alternative")])

        let routesData = RoutesDataMock.mock(
            primaryRoute: RouteInterfaceMock(route: mainRoute),
            alternativeRoutes: [
                RouteInterfaceMock(mainRoute: mainRoute, alternativeRoute: firstAlternative, routeIndex: 1),
                RouteInterfaceMock(mainRoute: mainRoute, alternativeRoute: secondAlternative, routeIndex: 2),
            ]
        )

        let navigationRoutes = try await NavigationRoutes(routesData: routesData)

        XCTAssertEqual(navigationRoutes.mainRoute.route.description, "main")
        XCTAssertEqual(
            navigationRoutes.alternativeRoutes.map(\.route.description),
            ["first-alternative", "second-alternative"]
        )
    }

    func testCreateRoutesDropsAlternativeWithoutRouteJson() async throws {
        let mainRoute = Route.mock(legs: [.mock(name: "main")])
        let goodAlternative = Route.mock(legs: [.mock(name: "good-alternative")])

        let routesData = RoutesDataMock.mock(
            primaryRoute: RouteInterfaceMock(route: mainRoute),
            alternativeRoutes: [
                RouteInterfaceMock(mainRoute: mainRoute, alternativeRoute: goodAlternative, routeIndex: 1),
                RouteInterfaceMock(responseJsonRef: .init(data: Data())),
            ]
        )

        let navigationRoutes = try await NavigationRoutes(routesData: routesData)

        XCTAssertEqual(navigationRoutes.alternativeRoutes.map(\.route.description), ["good-alternative"])
    }

    /// History replay removes the primary route from the decoded response array at its recorded index
    /// (`HistoryReader.swift:150`), which need not be 0.
    func testCreateRoutesIfPrimaryRouteIsNotFirstInResponse() async throws {
        let mainRoute = Route.mock(legs: [.mock(name: "main")])
        let alternative = Route.mock(legs: [.mock(name: "alternative")])

        let routesData = RoutesDataMock.mock(
            primaryRoute: RouteInterfaceMock(route: mainRoute, routeIndex: 1),
            alternativeRoutes: [
                RouteInterfaceMock(mainRoute: mainRoute, alternativeRoute: alternative, routeIndex: 0),
            ]
        )

        let navigationRoutes = try await NavigationRoutes(routesData: routesData)

        XCTAssertEqual(navigationRoutes.mainRoute.route.description, "main")
        XCTAssertEqual(navigationRoutes.alternativeRoutes.map(\.route.description), ["alternative"])
    }

    func testConvertToDirectionsRouteIfRouteIndexIsNotZero() async throws {
        let route = Route.mock(legs: [.mock(name: "route")])
        let nativeRoute = RouteInterfaceMock(route: route, routeIndex: 2)

        let convertedRoute = try await nativeRoute.convertToDirectionsRoute(NavigationRouteOptions.self)

        XCTAssertEqual(convertedRoute.description, route.description)
    }

    func testAlternativeRoutesFromNativeIfRouteIndicesAreNotZero() async throws {
        let mainRoute = Route.mock(legs: [.mock(name: "main")])
        let firstAlternative = Route.mock(legs: [.mock(name: "first-alternative")])
        let secondAlternative = Route.mock(legs: [.mock(name: "second-alternative")])

        let initialRoutes = await NavigationRoutes.mock(mainRoute: .mock(route: mainRoute))
        let nativeAlternatives = [
            RouteAlternative.mock(route: RouteInterfaceMock(
                mainRoute: mainRoute,
                alternativeRoute: firstAlternative,
                routeIndex: 1
            )),
            RouteAlternative.mock(route: RouteInterfaceMock(
                mainRoute: mainRoute,
                alternativeRoute: secondAlternative,
                routeIndex: 2
            )),
        ]

        let alternativeRoutes = await AlternativeRoute.fromNative(
            alternativeRoutes: nativeAlternatives,
            initialRoutes: initialRoutes
        )

        XCTAssertEqual(
            alternativeRoutes.map(\.route.description),
            ["first-alternative", "second-alternative"]
        )
    }

    /// End-to-end cover for the full-response path, using real native parsing rather than
    /// ``RouteInterfaceMock``. ``init(routeResponse:routeIndex:responseOrigin:)`` still receives a genuinely
    /// multi-route response and must keep resolving each route by its original index, so this guards the
    /// contract that the `fullRouteResponse:` initializer documents.
    func testCreateRoutesFromResponseWithTwoAlternatives() async throws {
        guard let routeResponse = RouteResponse.mock(
            bundle: .module,
            options: routeOptions,
            fileName: "alternativesRouteResponse"
        ) else {
            XCTFail("Cannot create RouteResponse")
            return
        }
        let expectedRoutes = try XCTUnwrap(routeResponse.routes)
        XCTAssertEqual(expectedRoutes.count, 3)

        var routeParserClient = RouteParserClient.testValue
        routeParserClient.parseDirectionsResponseForResponseDataRef = RouteParserClient.liveValue
            .parseDirectionsResponseForResponseDataRef
        routeParserClient.createRoutesData = RouteParserClient.liveValue.createRoutesData
        Environment.set(\.routeParserClient, routeParserClient)

        let navigationRoutes = try await NavigationRoutes(
            routeResponse: routeResponse,
            routeIndex: 0,
            responseOrigin: .online
        )

        XCTAssertEqual(navigationRoutes.mainRoute.route.description, expectedRoutes[0].description)
        XCTAssertEqual(
            navigationRoutes.alternativeRoutes.map(\.route.description),
            [expectedRoutes[1].description, expectedRoutes[2].description],
            "Each alternative must resolve to its own route, not to the main route"
        )
    }
}
