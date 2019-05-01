import XCTest
import MapboxDirections
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class InstructionsCardCollectionTests: XCTestCase {
    
    /**
     /// TODO:
     Create a delegate stud to test (Unit Test)
        1. guidanceCardCollection:previewFor:
     */
    
    var instructionsCardView: InstructionsCardView!
    
    override func tearDown() {
        super.tearDown()
        instructionsCardView = nil
    }
    
    func testVerifyInstructionsCardCustomStyle() {
        instructionsCardView = InstructionsCardView()
        XCTAssertTrue(instructionsCardView.style is DayInstructionsCardStyle)

        instructionsCardView.style = TestInstructionsCardStyle()
        XCTAssertTrue(instructionsCardView.style is TestInstructionsCardStyle)
    }
}

fileprivate class TestInstructionsCardStyle: InstructionsCardStyle {
    var cornerRadius: CGFloat = 10.0
    var backgroundColor: UIColor = .purple
    var highlightedBackgroundColor: UIColor = .blue
    lazy var primaryLabelNormalFont: UIFont = {
        return UIFont.boldSystemFont(ofSize: 20.0)
    }()
    var primaryLabelTextColor: UIColor = .green
    var primaryLabelHighlightedTextColor: UIColor = .red
    var secondaryLabelNormalFont: UIFont = {
        return UIFont.systemFont(ofSize: 15.0)
    }()
    var secondaryLabelTextColor: UIColor = .darkGray
    var secondaryLabelHighlightedTextColor: UIColor = .gray
    lazy var distanceLabelNormalFont: UIFont = {
       return UIFont.systemFont(ofSize: 16.0)
    }()
    var distanceLabelValueTextColor: UIColor = .yellow
    var distanceLabelUnitTextColor: UIColor = .orange
    lazy var distanceLabelUnitFont: UIFont = {
       return UIFont.systemFont(ofSize: 20.0)
    }()
    lazy var distanceLabelValueFont: UIFont = {
       return UIFont.systemFont(ofSize: 12.0)
    }()
    var distanceLabelHighlightedTextColor: UIColor = .red
    var maneuverViewPrimaryColor: UIColor = .blue
    var maneuverViewSecondaryColor: UIColor = .clear
    var maneuverViewHighlightedColor: UIColor = .brown
}
