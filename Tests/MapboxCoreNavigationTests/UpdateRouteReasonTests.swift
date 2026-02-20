import XCTest
import TestHelper
@testable import MapboxCoreNavigation

class UpdateRouteReasonTests: TestCase {
    func testIsProactive() {
        XCTAssertTrue(UpdateRouteReason.fastestRoute.isProactive)

        XCTAssertFalse(UpdateRouteReason.undefined.isProactive)
        XCTAssertFalse(UpdateRouteReason.alternative.isProactive)
        XCTAssertFalse(UpdateRouteReason.reroute.isProactive)
    }

    func testShouldPlayRerouteSound() {
        XCTAssertTrue(UpdateRouteReason.fastestRoute.shouldPlayRerouteSound)
        XCTAssertTrue(UpdateRouteReason.reroute.shouldPlayRerouteSound)

        XCTAssertFalse(UpdateRouteReason.undefined.shouldPlayRerouteSound)
        XCTAssertFalse(UpdateRouteReason.alternative.shouldPlayRerouteSound)
    }

}
