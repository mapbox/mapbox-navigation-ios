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
    
    func testAbbreviationPerformance() {
        let route = Fixture.route(from: "route-with-banner-instructions", waypoints: [Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165)), Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))])
        
        let allSteps = route.legs.flatMap { $0.steps }
        let allInstructions = allSteps.flatMap { $0.instructionsDisplayedAlongStep?.first?.primaryInstruction }.filter { $0 != nil }
        
        let label = InstructionLabel(frame: CGRect(origin: .zero, size:CGSize(width: 10, height: 50)))
        label.availableBounds = { return CGRect(origin: .zero, size: CGSize.iPhoneX) }
        
        self.measure {
            for instruction in allInstructions {
                let presenter = InstructionPresenter(instruction, dataSource: label, downloadCompletion: nil)
                label.attributedText = presenter.attributedText()
            }
        }
    }
}
