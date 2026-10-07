@testable import _MapboxNavigationTestHelpers
import MapboxCommon_Private.MBXExpected
import MapboxDirections
@testable import MapboxNavigationNative_Private
@_spi(MapboxInternal) @testable import MapboxNavigationCore
import XCTest

final class MapboxNavigatorOperationsDelegateTests: TestCase {
    override func setUp() {
        super.setUp()
        Environment.switchEnvironment(to: .test)
    }

    override func tearDown() {
        Environment.switchEnvironment(to: .live)
        super.tearDown()
    }

    func testNavigationRoutesFromRouteInterfacesBuildsPrimary() async throws {
        let mainRoute = Route.mock(legs: [.mock(name: "main")])
        let primary = RouteInterfaceMock(route: mainRoute)

        var routeParserClient = RouteParserClient.testValue
        routeParserClient.createRoutesData = { primaryRoute, _ in
            RoutesDataMock.mock(primaryRoute: primaryRoute)
        }
        Environment.set(\.routeParserClient, routeParserClient)

        let navigationRoutes = try await NavigationRoutes(routeInterfaces: [primary])

        XCTAssertEqual(navigationRoutes.mainRoute.route.description, "main")
        XCTAssertTrue(navigationRoutes.alternativeRoutes.isEmpty)
    }

    func testNavigationRoutesFromEmptyRouteInterfacesThrows() async {
        do {
            _ = try await NavigationRoutes(routeInterfaces: [])
            XCTFail("Expected NavigationRoutes to reject an empty route list")
        } catch {
            XCTAssertTrue(error is NavigationRoutesError)
        }
    }
}
