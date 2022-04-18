import XCTest
import UIKit
import CoreLocation
import TestHelper
import SnapshotTesting
@testable import MapboxNavigation

class UserPuckCourseViewSnapshotTests: TestCase {
    
    override func setUp() {
        super.setUp()
        isRecording = false
    }
    
    @available(iOS 13.0, *)
    func testUserPuckCourseViewPuckColorWhenChangingAppearance() {
        let frame = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
        let puckColor = Fixture.color(named: "user_puck_course_view_puck_color_set")
        
        // Simulate `UserPuckCourseView` puck color appearance in light mode.
        let lightUserPuckСourseView = UserPuckCourseView(frame: frame)
        lightUserPuckСourseView.puckView.overrideUserInterfaceStyle = .light
        lightUserPuckСourseView.puckColor = puckColor
        lightUserPuckСourseView.setNeedsDisplay()
        assertImageSnapshot(matching: lightUserPuckСourseView, as: .image(precision: 0.95))
        
        // Simulate `UserPuckCourseView` puck color appearance in dark mode.
        let darkUserPuckСourseView = UserPuckCourseView(frame: frame)
        darkUserPuckСourseView.puckView.overrideUserInterfaceStyle = .dark
        darkUserPuckСourseView.puckColor = puckColor
        darkUserPuckСourseView.setNeedsDisplay()
        assertImageSnapshot(matching: darkUserPuckСourseView, as: .image(precision: 0.95))
    }
    
    @available(iOS 13.0, *)
    func testUserPuckCourseViewFillAndShadowColorWhenChangingAppearance() {
        let frame = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
        let fillColor = Fixture.color(named: "user_puck_course_view_fill_color_set")
        let shadowColor = Fixture.color(named: "user_puck_course_view_shadow_color_set")
        
        // Simulate `UserPuckCourseView` fill and shadow colors appearance in light mode.
        let lightUserPuckСourseView = UserPuckCourseView(frame: frame)
        lightUserPuckСourseView.puckView.overrideUserInterfaceStyle = .light
        lightUserPuckСourseView.fillColor = fillColor
        lightUserPuckСourseView.shadowColor = shadowColor
        lightUserPuckСourseView.setNeedsDisplay()
        assertImageSnapshot(matching: lightUserPuckСourseView, as: .image(precision: 0.95))
        
        // Simulate `UserPuckCourseView` fill and shadow colors appearance in dark mode.
        let darkUserPuckСourseView = UserPuckCourseView(frame: frame)
        darkUserPuckСourseView.puckView.overrideUserInterfaceStyle = .dark
        darkUserPuckСourseView.fillColor = fillColor
        darkUserPuckСourseView.shadowColor = shadowColor
        darkUserPuckСourseView.setNeedsDisplay()
        assertImageSnapshot(matching: darkUserPuckСourseView, as: .image(precision: 0.95))
    }
    
    func testCourseUpdatable() {
        
        class CourseUpdatableMock: UIView, CourseUpdatable {
            
        }
        
        let courseUpdatableMock = CourseUpdatableMock()
        
        let course = 12.0
        let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.762939, longitude: -122.434755),
                                  altitude: 0.0,
                                  horizontalAccuracy: 0.0,
                                  verticalAccuracy: 0.0,
                                  course: 12.0,
                                  speed: 0.0,
                                  timestamp: Date())
        
        let direction = 24.0
        courseUpdatableMock.update(location: location,
                                   pitch: 0.0,
                                   direction: direction,
                                   animated: false,
                                   navigationCameraState: .following)
        
        let angle = CLLocationDegrees(atan2f(Float(courseUpdatableMock.transform.b),
                                             Float(courseUpdatableMock.transform.a))).toDegrees()
        XCTAssertEqual(angle, course - direction, accuracy: 0.1, "Direction angles of the puck should be almost equal.")
    }
    
    func testUserPuckCourseViewScale() {
        let frame = CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0)
        let userPuckСourseView = UserPuckCourseView(frame: frame)
        userPuckСourseView.puckColor = .red
        userPuckСourseView.fillColor = .green
        userPuckСourseView.shadowColor = .blue
        userPuckСourseView.setNeedsDisplay()
        
        // It is expected that the `UserPuckCourseView` is scaled by the customized frame instead of being trimmed.
        assertImageSnapshot(matching: userPuckСourseView, as: .image(precision: 0.95))
    }
}
