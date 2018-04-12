import Foundation
import XCTest
@testable import MapboxNavigation
@testable import MapboxDirections

class InstructionPresenterTests: XCTestCase {
    
    func testExitInstructionProvidesExit() {
                let exitAttribute = VisualInstructionComponent(type: .exit, text: "Exit", imageURL: nil, maneuverType: .takeOffRamp, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0)
                let exitCodeAttribute = VisualInstructionComponent(type: .exitCode, text: "123A", imageURL: nil, maneuverType: .takeOffRamp, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0)
                let label = InstructionLabel(frame: CGRect(origin: .zero, size:CGSize(width: 50, height: 50)))
        
                //FIXME: not ideal -- UIAutoLayout?
                label.availableBounds = { return label.frame }
        
                let presenter = InstructionPresenter([exitAttribute, exitCodeAttribute], dataSource: label)
                let attributed = presenter.attributedText()
        
                let attachment = attributed.attribute(.attachment, at: 0, effectiveRange: nil)
        
                XCTAssert(attachment is ExitAttachment, "Attachment for exit shield should be of type ExitAttachment")
    }
}
