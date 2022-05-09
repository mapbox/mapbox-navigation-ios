import Foundation
import XCTest
import MapboxCoreNavigation
import TestHelper

final class LeakTests: TestCase {
    func testNavigationService() {
        let leakTester = LeakTest {
            MapboxNavigationService(routeResponse: response,
                                    routeIndex: 0,
                                    routeOptions: routeOptions,
                                    customRoutingProvider: MapboxRoutingProvider(.offline),
                                    credentials: .mocked)
        }
        XCTAssertFalse(leakTester.isLeaking())
    }
}
