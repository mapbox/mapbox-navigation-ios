import _MapboxNavigationTestHelpers
import CoreLocation
import MapboxCommon_Private.MBXExpected
import MapboxDirections
import MapboxNavigationNative.MBNNRouteParser
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

    private lazy var routeResponse: RouteResponse? = {
        guard let fixtureURL = Bundle.module.url(
            forResource: "routeResponse",
            withExtension: "json",
            subdirectory: "Fixtures"
        ) else {
            XCTFail("File not found")
            return nil
        }

        guard let responseData = try? Data(contentsOf: fixtureURL) else {
            XCTFail("File cannot be read")
            return nil
        }
        do {
            let decoder = JSONDecoder()
            decoder.userInfo[.options] = routeOptions
            decoder.userInfo[.credentials] = Credentials.mock()
            return try decoder.decode(RouteResponse.self, from: responseData)
        } catch {
            XCTFail("File cannot be decoded, error: \(error)")
            return nil
        }
    }()

    private lazy var mapMatchingResponse: MapMatchingResponse? = {
        guard let fixtureURL = Bundle.module.url(
            forResource: "matchResponse",
            withExtension: "json",
            subdirectory: "Fixtures"
        ) else {
            XCTFail("File not found")
            return nil
        }

        guard let responseData = try? Data(contentsOf: fixtureURL) else {
            XCTFail("File cannot be read")
            return nil
        }
        do {
            let decoder = JSONDecoder()
            decoder.userInfo[.options] = matchOptions
            decoder.userInfo[.credentials] = Credentials.mock()
            return try decoder.decode(MapMatchingResponse.self, from: responseData)
        } catch {
            XCTFail("File cannot be decoded, error: \(error)")
            return nil
        }
    }()

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
}
