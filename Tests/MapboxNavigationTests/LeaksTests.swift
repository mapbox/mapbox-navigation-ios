import Foundation
import XCTest
@testable import MapboxNavigation
import TestHelper

final class LeaksTests: XCTestCase {
    func testUserCourseViewLeak() {
        let leakTester = LeakTest {
            UserPuckCourseView(frame: .zero)
        }
        XCTAssertFalse(leakTester.isLeaking())
    }
}
