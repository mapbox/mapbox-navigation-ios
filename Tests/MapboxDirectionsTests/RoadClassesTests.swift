@testable import MapboxDirections
import XCTest

final class RoadClassesTests: XCTestCase {
    @available(*, deprecated, message: "To be removed with RoadClasses(descriptions:)")
    func testInitFromDescriptionsFailsOnUnrecognizedToken() {
        // This strictness is the previously documented public API; `init(from:)` exists for the tolerant case.
        XCTAssertNil(RoadClasses(descriptions: ["toll", "some_future_api_value"]))
        XCTAssertEqual(RoadClasses(descriptions: ["toll", "motorway"]), [.toll, .motorway])
    }

    func testInitKeepsRecognizedTokensAndIgnoresUnrecognizedOnes() {
        let roadClasses = RoadClasses(from: ["toll", "some_future_api_value", "motorway"])
        XCTAssertEqual(roadClasses, [.toll, .motorway])
    }

    func testInitWithAllUnrecognizedTokensReturnsEmpty() {
        XCTAssertEqual(RoadClasses(from: ["some_future_api_value", "another_one"]), [])
    }

    @available(*, deprecated, message: "To be removed with RoadClasses(descriptions:)")
    func testInitWithAllRecognizedTokensMatchesStrictInit() {
        let descriptions = ["toll", "motorway", "ferry"]
        XCTAssertEqual(RoadClasses(from: descriptions), RoadClasses(descriptions: descriptions))
    }

    func testInitIgnoresSurroundingWhitespace() {
        XCTAssertEqual(RoadClasses(from: ["toll", " motorway", " "]), [.toll, .motorway])
    }
}
