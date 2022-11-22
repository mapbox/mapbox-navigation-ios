import MapboxDirections
@testable import MapboxCoreNavigation
import XCTest
import TestHelper

class RerouteTests: TestCase {

    func testSelectsMostSimilarRouteForRerouting() {
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

    func testSelectsMostSimilarRouteWhenCandidatesAreLonger() {
        let originalRoute = DummyRoute(description: "AAAAAAA")
        let candidates = [
            DummyRoute(description: "AAAAAAA12345"),
            DummyRoute(description: "AAAAAAA1234"),
        ]
        let mostCommonIndex = candidates.index(mostSimilarTo: originalRoute)
        XCTAssertEqual(mostCommonIndex, 1)
    }

    func testSelectsTheFastestRouteWhenCandidatesAreVeryLong() {
        // Here we select the fastest route because all of the candidates are more than 50% different
        let originalRoute = DummyRoute(description: "AAAAAA")
        let candidates = [
            DummyRoute(description: "AAAAAA123456789"),
            DummyRoute(description: "AAAAAA12345678"),
        ]
        let mostCommonIndex = candidates.index(mostSimilarTo: originalRoute)
        XCTAssertEqual(mostCommonIndex, 0)
    }

    func testSelectsMostSimilarRouteWhenCandidatesAreShorter() {
        let originalRoute = DummyRoute(description: "AAAAAA")
        let candidates = [
            DummyRoute(description: "AAAA"),
            DummyRoute(description: "AAAAA"),
        ]
        let mostCommonIndex = candidates.index(mostSimilarTo: originalRoute)
        XCTAssertEqual(mostCommonIndex, 1)
    }

    func testSelectsTheFastestRouteWhenCandidatesAreVeryShort() {
        // Here we select the fastest route because all of the candidates are more than 50% different
        let originalRoute = DummyRoute(description: "AAAAAA")
        let candidates = [
            DummyRoute(description: "AA"),
            DummyRoute(description: "AAA"),
        ]
        let mostCommonIndex = candidates.index(mostSimilarTo: originalRoute)
        XCTAssertEqual(mostCommonIndex, 0)
    }
}
