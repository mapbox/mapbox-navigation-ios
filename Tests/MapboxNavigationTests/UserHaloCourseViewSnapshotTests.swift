import XCTest
import UIKit
import TestHelper
import SnapshotTesting
@testable import MapboxNavigation

class UserHaloCourseViewSnapshotTests: TestCase {
    
    override func setUp() {
        super.setUp()
        isRecording = false
    }
    
    func testUserHaloCourseView() {
        let frame = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
        
        let userHaloCourseView = UserHaloCourseView(frame: frame)
        userHaloCourseView.haloColor = .blue
        userHaloCourseView.haloRingColor = .green
        userHaloCourseView.haloRadius = 45.0
        userHaloCourseView.haloBorderWidth = 5.0
        userHaloCourseView.draw(frame)
        assertImageSnapshot(matching: userHaloCourseView, as: .image(precision: 0.95))
    }
    
    func testUserHaloCourseViewMultipleDrawCycles() {
        let frame = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
        
        let userHaloCourseView = UserHaloCourseView(frame: frame)
        userHaloCourseView.haloColor = UIColor.blue.withAlphaComponent(0.2)
        userHaloCourseView.haloRingColor = UIColor.green.withAlphaComponent(0.2)
        userHaloCourseView.haloRadius = 45.0
        userHaloCourseView.haloBorderWidth = 5.0
        
        for _ in 0...10 {
            userHaloCourseView.draw(frame)
        }
        
        XCTAssertEqual(userHaloCourseView.layer.sublayers?.count, 1, "UserHaloCourseView should contain only one layer.")
        
        assertImageSnapshot(matching: userHaloCourseView, as: .image(precision: 0.95))
        
        userHaloCourseView.haloColor = .red
        userHaloCourseView.haloRingColor = .yellow
        userHaloCourseView.haloRadius = 20.0
        userHaloCourseView.haloBorderWidth = 10.0
        
        assertImageSnapshot(matching: userHaloCourseView, as: .image(precision: 0.95))
    }
    
    @available(iOS 13.0, *)
    func testUserHaloCourseViewColorWhenChangingAppearance() {
        let frame = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
        let haloColor = Fixture.color(named: "user_halo_color_set")
        let haloRingColor = Fixture.color(named: "user_halo_ring_color_set")
        
        // Simulate `UserHaloCourseView` color appearance in light mode.
        let lightUserHaloCourseView = UserHaloCourseView(frame: frame)
        lightUserHaloCourseView.overrideUserInterfaceStyle = .light
        lightUserHaloCourseView.haloColor = haloColor
        lightUserHaloCourseView.haloRingColor = haloRingColor
        lightUserHaloCourseView.haloRadius = 45.0
        lightUserHaloCourseView.haloBorderWidth = 5.0
        lightUserHaloCourseView.draw(frame)
        assertImageSnapshot(matching: lightUserHaloCourseView, as: .image(precision: 0.95))
        
        // Simulate `UserHaloCourseView` color appearance in dark mode.
        let darkUserHaloCourseView = UserHaloCourseView(frame: frame)
        darkUserHaloCourseView.overrideUserInterfaceStyle = .dark
        darkUserHaloCourseView.haloColor = haloColor
        darkUserHaloCourseView.haloRingColor = haloRingColor
        darkUserHaloCourseView.haloRadius = 45.0
        darkUserHaloCourseView.haloBorderWidth = 5.0
        darkUserHaloCourseView.draw(frame)
        assertImageSnapshot(matching: darkUserHaloCourseView, as: .image(precision: 0.95))
    }
}
