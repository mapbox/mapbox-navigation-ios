import XCTest
import Foundation
import SnapshotTesting
@testable import TestHelper
@testable import MapboxNavigation

class BannerDismissalViewControllerSnapshotTests: TestCase {
    var bannerDismissalViewController: BannerDismissalViewController!
    
    override func setUp() {
        super.setUp()
        isRecording = false
        bannerDismissalViewController = BannerDismissalViewController()
    }
    
    override func tearDown() {
        super.tearDown()
        bannerDismissalViewController = nil
    }
    
    func testBannerDismissalViewControllerDayStyle() {
        DayStyle().apply()
        assertImageSnapshot(matching: bannerDismissalViewController, as: .image(precision: 0.95))
    }
    
    func testBannerDismissalViewControllerNightStyle() {
        NightStyle().apply()
        assertImageSnapshot(matching: bannerDismissalViewController, as: .image(precision: 0.95))
    }
    
    func testBackTitleUpdate() {
        let newTitle = "Testing Title"
        bannerDismissalViewController.backTitle = newTitle
        XCTAssertEqual(newTitle, bannerDismissalViewController.backButton.currentTitle, "Failed to update the button title.")
    }
}
