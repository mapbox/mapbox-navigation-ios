@testable import MapboxCoreNavigation
@testable import MapboxNavigationNative

import XCTest

class IncidentImpactTests: XCTestCase {
    func testToStringMethodReturnsExpectedResult() {
        XCTAssertEqual(IncidentImpact.unknown.toString(), "unknown")
        XCTAssertEqual(IncidentImpact.critical.toString(), "critical")
        XCTAssertEqual(IncidentImpact.major.toString(), "major")
        XCTAssertEqual(IncidentImpact.minor.toString(), "minor")
        XCTAssertEqual(IncidentImpact.low.toString(), "low")
    }
}
