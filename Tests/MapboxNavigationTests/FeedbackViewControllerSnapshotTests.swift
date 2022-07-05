import XCTest
import Foundation
import SnapshotTesting
@testable import TestHelper
@testable import MapboxNavigation

class FeedbackViewControllerSnapshotTests: TestCase {
    
    var feedbackViewController: FeedbackViewController!
    
    override func setUp() {
        super.setUp()
        isRecording = false
        
        feedbackViewController = FeedbackViewController(eventsManager: NavigationEventsManagerSpy(), type: .passiveNavigation)
        DayStyle().apply()
    }
    
    override func tearDown() {
        super.tearDown()
        feedbackViewController = nil
    }
    
    func createDetailedFeedbackViewController() -> FeedbackSubtypeViewController? {
        guard feedbackViewController.sections.count > 0, let feedback = feedbackViewController.currentFeedback else {
              XCTFail("Failed to create detailed FeedbackViewController.")
            return nil
          }
        let item = feedbackViewController.sections[0]
        let detailedFeedbackViewController = FeedbackSubtypeViewController(eventsManager: NavigationEventsManagerSpy(),
                                                                           feedbackType: item.type,
                                                                           feedback: feedback)
        return detailedFeedbackViewController
    }
    
    func testDayFeedbackViewController() {
        assertImageSnapshot(matching: feedbackViewController, as: .image(precision: 0.95))
    }
    
    func testNightFeedbackViewController() {
        NightStyleSpy().apply()
        assertImageSnapshot(matching: feedbackViewController, as: .image(precision: 0.95))
    }
    
    func testDayDetailedFeedbackViewController() {
        guard let detailedFeedbackViewController = createDetailedFeedbackViewController() else {
              XCTFail("Failed to create detailed FeedbackViewController.")
            return
          }
        
        // test the day style of detailed FeedbackSubtypeViewController
        assertImageSnapshot(matching: detailedFeedbackViewController, as: .image(precision: 0.95))
        
        // test the day style of detailed FeedbackSubtypeViewController when selection
        let indexPath = IndexPath(row: 0, section: 0)
        detailedFeedbackViewController.collectionView(detailedFeedbackViewController.collectionView, didSelectItemAt: indexPath)
        assertImageSnapshot(matching: detailedFeedbackViewController, as: .image(precision: 0.95))
    }
    
    func testNightDetailedFeedbackViewController() {
        NightStyleSpy().apply()
        guard let detailedFeedbackViewController = createDetailedFeedbackViewController() else {
            XCTFail("Failed to create detailed FeedbackViewController.")
            return
        }
        
        // test the night style of detailed FeedbackSubtypeViewController
        assertImageSnapshot(matching: detailedFeedbackViewController, as: .image(precision: 0.95))
        
        // test the night style of detailed FeedbackSubtypeViewController when selection
        let indexPath = IndexPath(row: 0, section: 0)
        detailedFeedbackViewController.collectionView(detailedFeedbackViewController.collectionView, didSelectItemAt: indexPath)
        assertImageSnapshot(matching: detailedFeedbackViewController, as: .image(precision: 0.95))

        // test the detailed FeedbackSubtypeViewController keeping the selection after Style changes
        DayStyle().apply()
        assertImageSnapshot(matching: detailedFeedbackViewController, as: .image(precision: 0.95))

        // test the detailed FeedbackSubtypeViewController deselection function after Style changes
        detailedFeedbackViewController.collectionView(detailedFeedbackViewController.collectionView, didDeselectItemAt: indexPath)
        assertImageSnapshot(matching: detailedFeedbackViewController, as: .image(precision: 0.95))
    }
}

class NightStyleSpy: NightStyle {
    override func apply() {
        super.apply()
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)
        FeedbackSubtypeCollectionViewCell.appearance(for: traitCollection).normalCircleColor = .lightGray
        UILabel.appearance(for: traitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).textColor = .red
    }
}
