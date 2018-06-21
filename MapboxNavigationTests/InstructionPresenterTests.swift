import Foundation
import XCTest
@testable import MapboxNavigation
import MapboxDirections

class InstructionPresenterTests: XCTestCase {
    
    func testExitInstructionProvidesExit() {
        
        let exitAttribute = VisualInstructionComponent(type: .exit, text: "Exit", imageURL: nil, abbreviation: nil, abbreviationPriority: 0)
        let exitCodeAttribute = VisualInstructionComponent(type: .exitCode, text: "123A", imageURL: nil, abbreviation: nil, abbreviationPriority: 0)
        let exitInstruction = VisualInstruction(text: nil, maneuverType: .takeOffRamp, maneuverDirection: .right, components: [exitAttribute, exitCodeAttribute])
        
        let label = InstructionLabel(frame: CGRect(origin: .zero, size:CGSize(width: 50, height: 50)))

        //FIXME: not ideal -- UIAutoLayout?
        label.availableBounds = { return CGRect(origin: .zero, size: CGSize.iPhoneX) }

        let presenter = InstructionPresenter(exitInstruction, dataSource: label, downloadCompletion: nil)
        let attributed = presenter.attributedText()

        let attachment = attributed.attribute(.attachment, at: 0, effectiveRange: nil)

        XCTAssert(attachment is ExitAttachment, "Attachment for exit shield should be of type ExitAttachment")
    }

    /// NOTE: This test is disabled pending https://github.com/mapbox/mapbox-navigation-ios/issues/1468
    func x_testAbbreviationPerformance() {
        let route = Fixture.route(from: "route-with-banner-instructions", waypoints: [Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165)), Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))])
        
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
