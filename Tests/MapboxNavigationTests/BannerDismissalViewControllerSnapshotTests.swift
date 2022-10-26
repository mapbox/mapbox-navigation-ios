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
        DayStyle().apply()
        bannerDismissalViewController = BannerDismissalViewController()
    }
    
    override func tearDown() {
        super.tearDown()
        bannerDismissalViewController = nil
    }
    
    func testBannerDismissalViewController() {
        assertImageSnapshot(matching: bannerDismissalViewController, as: .image(precision: 0.95))
    }
    
    
    func testBackTitleUpdate() {
        bannerDismissalViewController.backTitle = "Testing Title"
        assertImageSnapshot(matching: bannerDismissalViewController, as: .image(precision: 0.95))
    }
}
