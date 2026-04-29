@testable import MapboxNavigationCore
import XCTest

final class CongestionLevelTests: XCTestCase {
    var routeLeg: RouteLeg!

    override func setUp() {
        super.setUp()

        routeLeg = RouteLeg(
            steps: [],
            name: "5th Street",
            distance: 92.2,
            expectedTravelTime: 24.6,
            profileIdentifier: .automobile
        )
    }

    func testResolvedCongestionLevelsNumericPreference() {
        routeLeg.segmentCongestionLevels = [.heavy, .low, .low, .moderate]
        routeLeg.segmentNumericCongestionLevels = [nil, 3, 50]

        let resolvedCongestionLevels = routeLeg.resolveCongestionLevels(using: .default)
        let expectedCongestionLevels = routeLeg.segmentNumericCongestionLevels?.map {
            CongestionLevel(numericValue: $0, configuration: .default)
        }
        XCTAssertEqual(resolvedCongestionLevels, expectedCongestionLevels)
    }

    func testResolvedCongestionLevelsAbsentNumeric() {
        routeLeg.segmentCongestionLevels = [.heavy, .low, .low, .moderate]
        routeLeg.segmentNumericCongestionLevels = nil

        let resolvedCongestionLevels = routeLeg.resolveCongestionLevels(using: .default)
        XCTAssertEqual(resolvedCongestionLevels, routeLeg.segmentCongestionLevels)
    }

    func testResolvedCongestionLevelsAbsenNumericAndLevels() {
        routeLeg.segmentCongestionLevels = nil
        routeLeg.segmentNumericCongestionLevels = nil

        let resolvedCongestionLevels = routeLeg.resolveCongestionLevels(using: .default)
        XCTAssertNil(resolvedCongestionLevels)
    }
}
