import XCTest
@testable import MapboxNavigationNative
@testable import MapboxCoreNavigation

class RouteStateTests: XCTestCase {
    func testDescriptionPropertyReturnsExpectedValue() {
        XCTAssertEqual(RouteState.invalid.description, "invalid")
        XCTAssertEqual(RouteState.initialized.description, "initialized")
        XCTAssertEqual(RouteState.tracking.description, "tracking")
        XCTAssertEqual(RouteState.complete.description, "complete")
        XCTAssertEqual(RouteState.offRoute.description, "offRoute")
        XCTAssertEqual(RouteState.stale.description, "stale")
        XCTAssertEqual(RouteState.uncertain.description, "uncertain")
    }
}
