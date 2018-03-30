import Foundation
import XCTest
@testable import MapboxNavigation
import MapboxDirections

let fixtureString = """
{
"distanceAlongGeometry": 503.1,
"primary": {
"type": "off ramp",
"modifier": "right",
"components": [
{
"text": "Exit",
"type": "exit"
},
{
"text": "25",
"type": "exit-number"
},
{
"text": "335",
"type": "text"
},
{
"text": "Sud",
"type": "text"
}
],
"text": "Exit 25 335 Sud"
},
"secondary": null
}
"""

class InstructionPresenterTests: XCTestCase {
    
    static let fixtureData = fixtureString.data(using: .utf8)
    static let fixtureJSON: [String: Any] = try! JSONSerialization.jsonObject(with: InstructionPresenterTests.fixtureData!, options: []) as! [String: Any]
    static let subject = VisualInstruction(json: InstructionPresenterTests.fixtureJSON, drivingSide: .right)

    func testExitRecognized() {
        let subject = InstructionPresenterTests.subject
        XCTAssertTrue(subject.primaryTextComponents.isExit, "Not recognizing exit instruction components as an exit")
    }
}
