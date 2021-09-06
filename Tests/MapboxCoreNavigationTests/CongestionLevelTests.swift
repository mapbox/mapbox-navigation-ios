import XCTest
@testable import MapboxCoreNavigation

class CongestionLevelTests: XCTestCase {

    func testCongestionRangeDefaultValues() {
        CongestionRange.resetCongestionRangesToDefault()
    }
}
