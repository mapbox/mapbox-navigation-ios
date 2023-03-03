import XCTest
import MapboxNavigationNative
@testable import MapboxCoreNavigation

final class RouteChangeReasonTests: XCTestCase {
    func testNavNativeValue() {
        XCTAssertEqual(RouteChangeReason.cleanUp.navNativeValue, .cleanUp)
        XCTAssertEqual(RouteChangeReason.startNewRoute.navNativeValue, .newRoute)
        XCTAssertEqual(RouteChangeReason.switchToAlternative.navNativeValue, .alternative)
        XCTAssertEqual(RouteChangeReason.reroute.navNativeValue, .reroute)
        XCTAssertEqual(RouteChangeReason.fallbackToOffline.navNativeValue, .fallbackToOffline)
        XCTAssertEqual(RouteChangeReason.restoreToOnline.navNativeValue, .restoreToOnline)
        XCTAssertEqual(RouteChangeReason.switchToOnline.navNativeValue, .switchToOnline)
        XCTAssertEqual(RouteChangeReason.fastestRouteAvailable.navNativeValue, .fastestRoute)
    }
}
