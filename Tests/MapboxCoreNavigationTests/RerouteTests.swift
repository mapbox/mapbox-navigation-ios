import MapboxDirections
@testable import MapboxCoreNavigation
import XCTest
import TestHelper

class RerouteTests: XCTestCase {

    func testSelectsMostSililarRouteForRerouting() {
        let originalRoute = DummyRoute(description: "AAAAA")
        let candidates = [
            DummyRoute(description: "AABBB"),
            DummyRoute(description: "AAABB"),
            DummyRoute(description: "AAAAB"),
        ]

        let mostCommonIndex = candidates.index(mostSimilarTo: originalRoute)
        XCTAssertEqual(mostCommonIndex, 2)
    }

    func testSelectsFastestRouteIfAllCandidatesAreVeryDifferent() {
        let originalRoute = DummyRoute(description: "AAAAA")
        let candidates = [
            DummyRoute(description: "ABBBB"),
            DummyRoute(description: "AABBB"),
        ]

        let mostCommonIndex = candidates.index(mostSimilarTo: originalRoute)
        XCTAssertEqual(mostCommonIndex, 0)
    }

    func testReturnsNilIfReroutesArrayIsEmpty() {
        XCTAssertNil([Route]().index(mostSimilarTo: DummyRoute(description: "")))
    }
}
