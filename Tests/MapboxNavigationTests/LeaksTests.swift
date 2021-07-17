import Foundation
import XCTest
@testable import MapboxNavigation
import TestHelper

final class LeaksTests: TestCase {
    func testUserCourseViewLeak() {
        let leakTester = LeakTest {
            UserPuckCourseView(frame: .zero)
        }
        XCTAssertFalse(leakTester.isLeaking())
    }
}
