import Foundation
import XCTest
import MapboxCoreNavigation
import TestHelper

final class LeakTests: TestCase {
    func testNavigationService() {
        let leakTester = LeakTest {
            MapboxNavigationService(indexedRouteResponse: IndexedRouteResponse(routeResponse: makeRouteResponse(),
                                                                               routeIndex: 0),
                                    customRoutingProvider: MapboxRoutingProvider(.offline),
                                    credentials: .mocked)
        }
        XCTAssertFalse(leakTester.isLeaking())
    }
}
