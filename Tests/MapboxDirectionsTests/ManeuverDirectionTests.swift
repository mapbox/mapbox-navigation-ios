@testable import MapboxDirections
import XCTest

class ManeuverDirectionTests: XCTestCase {
    func testDecoding() {
        let examples: [Example<String, ManeuverDirection>] = [
            Example("sharp right", .sharpRight),
            Example("right", .right),
            Example("slight right", .slightRight),
            Example("sharp left", .sharpLeft),
            Example("left", .left),
            Example("slight left", .slightLeft),
            Example("uturn", .uTurn),
            Example("incorrect value", .undefined),
        ]

        let decoder = JSONDecoder()

        for example in examples {
            let decoded = try? decoder.decode(
                CodableContainer<ManeuverDirection>.self,
                from: jsonData(type: example.input)
            )

            XCTAssertEqual(decoded?.wrapped, example.expected)
        }
    }

    private func jsonData(type: String) -> Data {
        return """
        {
            "wrapped": "\(type)"
        }
        """.data(using: .utf8)!
    }
}

private struct Example<Input, Expected> {
    let input: Input
    let expected: Expected

    init(_ input: Input, _ expected: Expected) {
        self.input = input
        self.expected = expected
    }
}
