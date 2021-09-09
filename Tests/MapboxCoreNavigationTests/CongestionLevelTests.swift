import CoreLocation
import MapboxDirections
import TestHelper
import XCTest

@testable import MapboxCoreNavigation

class CongestionLevelTests: TestCase {

    func testResetCongestionRangesToDefault() {
        CongestionRange.resetCongestionRangesToDefault()

        XCTAssertEqual(CongestionRange.low, CongestionRangeLow)
        XCTAssertEqual(CongestionRange.moderate, CongestionRangeModerate)
        XCTAssertEqual(CongestionRange.heavy, CongestionRangeHeavy)
        XCTAssertEqual(CongestionRange.severe, CongestionRangeSevere)
    }

    func testResolvedCongestionLevelsNumericPreference() {
        let routeLeg = RouteLeg(steps: [],
                                name: "5th Street",
                                distance: 92.2,
                                expectedTravelTime: 24.6,
                                profileIdentifier: .automobile)

        routeLeg.segmentCongestionLevels = [.heavy, .low, .low, .moderate]
        routeLeg.segmentNumericCongestionLevels = [nil, 3, 50]

        XCTAssertEqual(routeLeg.resolvedCongestionLevels, routeLeg.segmentNumericCongestionLevels?.map(CongestionLevel.init))
    }

    func testResolvedCongestionLevelsAbsentNumeric() {
        let routeLeg = RouteLeg(steps: [],
                                name: "5th Street",
                                distance: 92.2,
                                expectedTravelTime: 24.6,
                                profileIdentifier: .automobile)

        routeLeg.segmentCongestionLevels = [.heavy, .low, .low, .moderate]
        routeLeg.segmentNumericCongestionLevels = nil

        XCTAssertEqual(routeLeg.resolvedCongestionLevels, routeLeg.segmentCongestionLevels)
    }

    func testResolvedCongestionLevelsAbsenNumericAndLevels() {
        let routeLeg = RouteLeg(steps: [],
                                name: "5th Street",
                                distance: 92.2,
                                expectedTravelTime: 24.6,
                                profileIdentifier: .automobile)

        routeLeg.segmentCongestionLevels = nil
        routeLeg.segmentNumericCongestionLevels = nil

        XCTAssertEqual(routeLeg.resolvedCongestionLevels, nil)
    }
}
