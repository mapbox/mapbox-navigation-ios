import XCTest
import TestHelper
@testable import MapboxCoreNavigation

class DateTests: TestCase {
    func testISO8601() {
        // https://github.com/mapbox/mapbox-navigation-ios/issues/2327
        let epoch = Date(timeIntervalSinceReferenceDate: 0)
        XCTAssertEqual(epoch.ISO8601, "2001-01-01T00:00:00.000+0000", "ISO 8601 format should include milliseconds and full time zone for literal consistency with original event implementation")
    }
}
