import XCTest
@testable import MapboxCoreNavigation

class StringTests: XCTestCase {
    func testMinimumEditDistance() {
        let fromString = "hello this is a test"
        let toString = "hello"
        let distance = fromString.minimumEditDistance(to: toString)
        XCTAssertEqual(distance, 15)
    }
    
    func testMinimumEditDistanceFromEmptyString() {
        let fromString = ""
        let toString = "hello"
        let distance = fromString.minimumEditDistance(to: toString)
        XCTAssertEqual(distance, 5)
    }
    
    func testMinimumEditDistanceToEmptyString() {
        let fromString = "hello"
        let toString = ""
        let distance = fromString.minimumEditDistance(to: toString)
        XCTAssertEqual(distance, 5)
    }
}
