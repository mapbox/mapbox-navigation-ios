@testable import MapboxDirections
import XCTest

class TransportTypeTests: XCTestCase {
    func testDecoding() {
        let examples: [Example<String, TransportType>] = [
            Example("driving", .automobile),
            Example("ferry", .ferry),
            Example("movable bridge", .movableBridge),
            Example("unaccessible", .inaccessible),
            Example("walking", .walking),
            Example("pushing bike", .walking),
            Example("cycling", .cycling),
            Example("train", .train),
        ]

        let decoder = JSONDecoder()

        for example in examples {
            let decoded = try? decoder.decode(
                CodableContainer<TransportType>.self,
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
