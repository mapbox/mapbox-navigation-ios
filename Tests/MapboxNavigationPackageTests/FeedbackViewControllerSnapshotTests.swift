import Foundation
@testable import MapboxNavigationCore
@testable import MapboxNavigationUIKit
import SnapshotTesting
@testable import TestHelper
import XCTest

@MainActor
class FeedbackViewControllerSnapshotTests: TestCase {
    var feedbackViewController: FeedbackViewController!

    override func setUp() {
        super.setUp()
        let eventsManager = navigationProvider.eventsManager()
        feedbackViewController = FeedbackViewController(eventsManager: eventsManager, type: .passiveNavigation)
        DayStyle().apply()
    }

    override func tearDown() {
        feedbackViewController = nil
        super.tearDown()
    }

    func testDayFeedbackViewController() {
        assertImageSnapshot(matching: feedbackViewController, as: .image(precision: 0.99))
    }

    func testNightFeedbackViewController() {
        NightStyleSpy().apply()
        assertImageSnapshot(matching: feedbackViewController, as: .image(precision: 0.99))
    }
}

class NightStyleSpy: NightStyle {
    override func apply() {
        super.apply()
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)
        FeedbackSubtypeCollectionViewCell.appearance(for: traitCollection).normalCircleColor = .lightGray
        UILabel.appearance(for: traitCollection, whenContainedInInstancesOf: [FeedbackViewController.self])
            .textColor = .red
    }
}
