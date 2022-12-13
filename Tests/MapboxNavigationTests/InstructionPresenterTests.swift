import Foundation
import XCTest
import CoreLocation
import MapboxDirections
import MapboxCoreNavigation
import TestHelper
@testable import MapboxNavigation

class InstructionPresenterTests: TestCase {
    func testExitInstructionProvidesExit() {
        let exitAttribute = VisualInstruction.Component.exit(text: .init(text: "Exit", abbreviation: nil, abbreviationPriority: nil))
        let exitCodeAttribute = VisualInstruction.Component.exitCode(text: .init(text: "123A", abbreviation: nil, abbreviationPriority: nil))
        let exitInstruction = VisualInstruction(text: nil, maneuverType: .takeOffRamp, maneuverDirection: .right, components: [exitAttribute, exitCodeAttribute])
        
        let label = InstructionLabel(frame: CGRect(origin: .zero, size:CGSize(width: 50, height: 50)))

        //FIXME: not ideal -- UIAutoLayout?
        label.availableBounds = { return CGRect(origin: .zero, size: CGSize.iPhoneX) }

        let presenter = InstructionPresenter(exitInstruction,
                                             dataSource: label,
                                             traitCollection: UITraitCollection(userInterfaceIdiom: .phone),
                                             downloadCompletion: nil)
        
        let attributed = presenter.attributedText()

        let attachment = attributed.attribute(.attachment, at: 0, effectiveRange: nil)

        XCTAssert(attachment is ExitAttachment, "Attachment for exit shield should be of type ExitAttachment; got \(String(describing: attachment.self))")
    }

}
