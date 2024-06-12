import Foundation
@testable import MapboxNavigationUIKit
import SnapshotTesting
@testable import TestHelper
import XCTest

class BannerDismissalViewControllerSnapshotTests: TestCase {
    var bannerDismissalViewController: BannerDismissalViewController!

    override func setUp() {
        super.setUp()
        isRecording = false
        bannerDismissalViewController = BannerDismissalViewController()
    }

    override func tearDown() {
        bannerDismissalViewController = nil
        super.tearDown()
    }

    func testBannerDismissalViewControllerDayStyle() {
        DayStyle().apply()
        assertImageSnapshot(matching: bannerDismissalViewController, as: .image(precision: 0.99))
    }

    func testBannerDismissalViewControllerNightStyle() {
        NightStyle().apply()
        assertImageSnapshot(matching: bannerDismissalViewController, as: .image(precision: 0.99))
    }

    func testBackTitleUpdate() {
        let newTitle = "Testing Title"
        bannerDismissalViewController.backTitle = newTitle
        XCTAssertEqual(
            newTitle,
            bannerDismissalViewController.backButton.currentTitle,
            "Failed to update the button title."
        )
    }
}
