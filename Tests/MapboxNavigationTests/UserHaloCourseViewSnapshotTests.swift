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
        userHaloCourseView.haloView.draw(frame)
        assertImageSnapshot(matching: userHaloCourseView, as: .image(precision: 0.95))
    }
    
    @available(iOS 13.0, *)
    func testUserHaloCourseViewColorWhenChangingAppearance() {
        let frame = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
        let haloColor = Fixture.color(named: "user_halo_color_set")
        let haloRingColor = Fixture.color(named: "user_halo_ring_color_set")
        
        // Simulate `UserHaloCourseView` color appearance in light mode.
        let lightUserHaloCourseView = UserHaloCourseView(frame: frame)
        lightUserHaloCourseView.haloView.overrideUserInterfaceStyle = .light
        lightUserHaloCourseView.haloColor = haloColor
        lightUserHaloCourseView.haloRingColor = haloRingColor
        lightUserHaloCourseView.haloRadius = 45.0
        lightUserHaloCourseView.haloBorderWidth = 5.0
        lightUserHaloCourseView.haloView.draw(frame)
        assertImageSnapshot(matching: lightUserHaloCourseView, as: .image(precision: 0.95))
        
        // Simulate `UserHaloCourseView` color appearance in dark mode.
        let darkUserHaloCourseView = UserHaloCourseView(frame: frame)
        darkUserHaloCourseView.haloView.overrideUserInterfaceStyle = .dark
        darkUserHaloCourseView.haloColor = haloColor
        darkUserHaloCourseView.haloRingColor = haloRingColor
        darkUserHaloCourseView.haloRadius = 45.0
        darkUserHaloCourseView.haloBorderWidth = 5.0
        darkUserHaloCourseView.haloView.draw(frame)
        assertImageSnapshot(matching: darkUserHaloCourseView, as: .image(precision: 0.95))
    }
}
