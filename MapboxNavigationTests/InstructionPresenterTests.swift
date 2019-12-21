import Foundation
import XCTest
import MapboxDirections
import TestHelper
@testable import MapboxNavigation

class InstructionPresenterTests: XCTestCase {
    func testExitInstructionProvidesExit() {
        let exitAttribute = VisualInstruction.Component.exit(text: .init(text: "Exit", abbreviation: nil, abbreviationPriority: nil))
        let exitCodeAttribute = VisualInstruction.Component.exitCode(text: .init(text: "123A", abbreviation: nil, abbreviationPriority: nil))
        let exitInstruction = VisualInstruction(text: nil, maneuverType: .takeOffRamp, maneuverDirection: .right, components: [exitAttribute, exitCodeAttribute])
        
        let label = InstructionLabel(frame: CGRect(origin: .zero, size:CGSize(width: 50, height: 50)))

        //FIXME: not ideal -- UIAutoLayout?
        label.availableBounds = { return CGRect(origin: .zero, size: CGSize.iPhoneX) }

        let presenter = InstructionPresenter(exitInstruction, dataSource: label, downloadCompletion: nil)
        let attributed = presenter.attributedText()

        let attachment = attributed.attribute(.attachment, at: 0, effectiveRange: nil)

        XCTAssert(attachment is ExitAttachment, "Attachment for exit shield should be of type ExitAttachment; got \(String(describing: attachment.self))")
    }

    /// NOTE: This test is disabled pending https://github.com/mapbox/mapbox-navigation-ios/issues/1468
    func x_testAbbreviationPerformance() {
        let route = Fixture.route(from: "route-with-banner-instructions")
        
        let steps = route.legs.flatMap { $0.steps }
        let instructions = steps.compactMap { $0.instructionsDisplayedAlongStep?.first?.primaryInstruction }
        
        let label = InstructionLabel(frame: CGRect(origin: .zero, size: CGSize.iPhone5))
        label.availableBounds = { return CGRect(origin: .zero, size: CGSize.iPhone5) }
        
        self.measure {
            for instruction in instructions {
                let presenter = InstructionPresenter(instruction, dataSource: label, downloadCompletion: nil)
                label.attributedText = presenter.attributedText()
            }
        }
    }
}
