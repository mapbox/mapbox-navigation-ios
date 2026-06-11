@testable import MapboxDirections
import XCTest

class ManeuverDirectionTests: XCTestCase {
    func testDecoding() {
        let examples: [Example<String, ManeuverDirection>] = [
            Example("sharp right", .sharpRight),
            Example("right", .right),
            Example("slight right", .slightRight),
            Example("straight", .straightAhead),
            Example("sharp left", .sharpLeft),
            Example("left", .left),
            Example("slight left", .slightLeft),
            Example("uturn", .uTurn),
            Example("undefined", .undefined),
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

    func testEncodingUndefined() throws {
        let container = CodableContainer(wrapped: ManeuverDirection.undefined)
        let data = try JSONEncoder().encode(container)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
        XCTAssertEqual(json["wrapped"], "undefined")
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
