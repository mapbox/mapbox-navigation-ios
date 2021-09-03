import XCTest
@testable import MapboxCoreNavigation

class CongestionLevelTests: XCTestCase {

    func testCongestionRangeDefaulValues() {
        CongestionRange.resetCongestionRangesToDefault()
    }
}
