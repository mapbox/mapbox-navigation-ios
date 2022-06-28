import XCTest
import Foundation
import MapboxDirections
import SnapshotTesting
@testable import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

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
        UILabel.appearance(whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .black
        UILabel.appearance(whenContainedInInstancesOf: [FeedbackViewController.self]).textColor = .white
        FeedbackStyleView.appearance(whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .black
        FeedbackCollectionView.appearance().backgroundColor = .black
        FeedbackCollectionView.appearance().cellColor = .white
        assertImageSnapshot(matching: feedbackViewController, as: .image(precision: 0.95))
    }
    
    func testDetailedFeedbackViewControllerChangingAppearance() {
        guard let detailedFeedbackViewController = createDetailedFeedbackViewController() else {
              XCTFail("Failed to create detailed FeedbackViewController.")
            return
          }
        
        let indexPath = IndexPath(row: 0, section: 0)
        // test the day style of detailed FeedbackSubtypeViewController
        assertImageSnapshot(matching: detailedFeedbackViewController, as: .image(precision: 0.95))
        
        // test the day style of detailed FeedbackSubtypeViewController when selection.
        detailedFeedbackViewController.collectionView(detailedFeedbackViewController.collectionView, didSelectItemAt: indexPath)
        assertImageSnapshot(matching: detailedFeedbackViewController, as: .image(precision: 0.95))
        
        // test the detailed FeedbackSubtypeViewController reloading data after selection.
        UILabel.appearance(whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .black
        UILabel.appearance(whenContainedInInstancesOf: [FeedbackViewController.self]).textColor = .white
        FeedbackStyleView.appearance(whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .black
        FeedbackCollectionView.appearance().backgroundColor = .black
        FeedbackCollectionView.appearance().cellColor = .white
        FeedbackSubtypeCollectionViewCell.appearance().normalCircleColor = .black
        FeedbackSubtypeCollectionViewCell.appearance().normalCircleOutlineColor = .lightText
        assertImageSnapshot(matching: detailedFeedbackViewController, as: .image(precision: 0.95))
        
        // test the detailed FeedbackSubtypeViewController for deselection after changing appearance.
        detailedFeedbackViewController.collectionView(detailedFeedbackViewController.collectionView, didDeselectItemAt: indexPath)
        assertImageSnapshot(matching: detailedFeedbackViewController, as: .image(precision: 0.95))
    }
}
