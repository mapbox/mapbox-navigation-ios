import XCTest
import UIKit
import TestHelper
import SnapshotTesting
@testable import MapboxNavigation

class UserPuckCourseViewSnapshotTests: TestCase {
    
    override func setUp() {
        super.setUp()
        isRecording = false
    }
    
    @available(iOS 13.0, *)
    func testUserPuckCourseViewWhenChangingAppearance() {
        let frame = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
        let puckColor = Fixture.color(named: "user_puck_course_view_color_set")
        
        // Simulate `UserPuckCourseView` appearance in light mode.
        let lightUserPuckСourseView = UserPuckCourseView(frame: frame)
        lightUserPuckСourseView.puckView.overrideUserInterfaceStyle = .light
        lightUserPuckСourseView.puckColor = puckColor
        lightUserPuckСourseView.stalePuckColor = puckColor
        lightUserPuckСourseView.puckView.draw(frame)
        assertImageSnapshot(matching: lightUserPuckСourseView, as: .image(precision: 0.95))
        
        // Simulate `UserPuckCourseView` appearance in dark mode.
        let darkUserPuckСourseView = UserPuckCourseView(frame: frame)
        darkUserPuckСourseView.puckView.overrideUserInterfaceStyle = .dark
        darkUserPuckСourseView.puckColor = puckColor
        darkUserPuckСourseView.stalePuckColor = puckColor
        darkUserPuckСourseView.puckView.draw(frame)
        assertImageSnapshot(matching: darkUserPuckСourseView, as: .image(precision: 0.95))
    }
}
