import _MapboxNavigationTestHelpers
import CoreLocation
@testable import MapboxNavigationCore
import MapboxNavigationNative
import XCTest

final class MapMatchingResultTests: XCTestCase {
    func testIsOffRoadIf1() {
        let status = NavigationStatus.mock(offRoadProba: 1)
        let result = MapMatchingResult(status: status)
        XCTAssertTrue(result.isOffRoad)
        XCTAssertEqual(result.offRoadProbability, 1)
    }

    func testIsOffRoadIf051() {
        let status = NavigationStatus.mock(offRoadProba: 0.51)
        let result = MapMatchingResult(status: status)
        XCTAssertTrue(result.isOffRoad)
        XCTAssertEqual(result.offRoadProbability, 0.51, accuracy: 1e-6)
    }

    func testIsOffRoadIf05() {
        let status = NavigationStatus.mock(offRoadProba: 0.5)
        let result = MapMatchingResult(status: status)
        XCTAssertFalse(result.isOffRoad)
        XCTAssertEqual(result.offRoadProbability, 0.5)
    }

    func testIsTeleport() {
        let status = NavigationStatus.mock(mapMatcherOutput: .mock(isTeleport: true))
        let result = MapMatchingResult(status: status)
        XCTAssertTrue(result.isTeleport)
    }

    func testIsNotTeleport() {
        let status = NavigationStatus.mock(mapMatcherOutput: .mock(isTeleport: false))
        let result = MapMatchingResult(status: status)
        XCTAssertFalse(result.isTeleport)
    }

    func testDefaultRoadEdgeMatchProbability() {
        let status = NavigationStatus.mock()
        let result = MapMatchingResult(status: status)
        XCTAssertEqual(result.roadEdgeMatchProbability, 0)
    }

    func testRoadEdgeMatchProbability() {
        let status = NavigationStatus.mock(mapMatcherOutput: .mock(
            matches: [.mock(proba: 0.7), .mock(proba: 0.5)]
        ))
        let result = MapMatchingResult(status: status)
        XCTAssertEqual(result.roadEdgeMatchProbability, 0.7, accuracy: 1e-6)
    }

    func testKeyPoints() {
        let location1 = CLLocation(latitude: 1, longitude: 2)
        let location2 = CLLocation(latitude: 3, longitude: 4)
        let status = NavigationStatus.mock(keyPoints: [
            .init(location1),
            .init(location2, isMock: true),
        ])
        let result = MapMatchingResult(status: status)
        let expectedLocations = [location1, location2]
        XCTAssertEqual(result.keyPoints.map(\.coordinate), expectedLocations.map(\.coordinate))
    }
}
