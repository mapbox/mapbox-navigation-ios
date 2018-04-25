import Foundation
import XCTest
@testable import MapboxNavigation
@testable import MapboxDirections

class InstructionPresenterTests: XCTestCase {
    
    func testExitInstructionProvidesExit() {
        
        let exitAttribute = VisualInstructionComponent(type: .exit, text: "Exit", imageURL: nil, abbreviation: nil, abbreviationPriority: 0)
        let exitCodeAttribute = VisualInstructionComponent(type: .exitCode, text: "123A", imageURL: nil, abbreviation: nil, abbreviationPriority: 0)
        let exitInstruction = VisualInstruction(text: nil, maneuverType: .takeOffRamp, maneuverDirection: .right, textComponents: [exitAttribute, exitCodeAttribute])
        
        let label = InstructionLabel(frame: CGRect(origin: .zero, size:CGSize(width: 50, height: 50)))

        //FIXME: not ideal -- UIAutoLayout?
        label.availableBounds = { return CGRect(origin: .zero, size: CGSize.iPhoneX) }

        let presenter = InstructionPresenter(exitInstruction, dataSource: label, downloadCompletion: nil)
        let attributed = presenter.attributedText()

        let attachment = attributed.attribute(.attachment, at: 0, effectiveRange: nil)

        XCTAssert(attachment is ExitAttachment, "Attachment for exit shield should be of type ExitAttachment")
    }
}
