import XCTest
import TestHelper
@testable import MapboxNavigationNative
@testable import MapboxCoreNavigation

class RouteStateTests: TestCase {
    func testDescriptionPropertyReturnsExpectedValue() {
        XCTAssertEqual(RouteState.invalid.description, "invalid")
        XCTAssertEqual(RouteState.initialized.description, "initialized")
        XCTAssertEqual(RouteState.tracking.description, "tracking")
        XCTAssertEqual(RouteState.complete.description, "complete")
        XCTAssertEqual(RouteState.offRoute.description, "offRoute")
        XCTAssertEqual(RouteState.uncertain.description, "uncertain")
    }
}
