@testable import MapboxNavigationCore
import Turf
import XCTest

final class LineStringSlicingMetadataTests: XCTestCase {
    // 0.001° ~ 111.1 m
    let stepMeters: LocationDistance = 111.1
    let stepDegree: LocationDegrees = 0.001

    func testSlicingMetadata() throws {
        let initail = LineString(
            [
                .init(latitude: 0, longitude: 0),
                .init(latitude: 0, longitude: 0 + stepDegree),
                .init(latitude: 0, longitude: 0 + stepDegree * 2),
                .init(latitude: 0, longitude: 0 + stepDegree),
                .init(latitude: 0, longitude: 0),
            ]
        )

        let step1 = try XCTUnwrap(initail.slicingMetadata(at: stepMeters / 2))
        let trailing1 = step1.trailingLineString
        XCTAssertEqual(trailing1.coordinates.count, 5)
        let step2 = try XCTUnwrap(trailing1.slicingMetadata(at: stepMeters))
        let trailing2 = step2.trailingLineString
        XCTAssertEqual(trailing2.coordinates.count, 4)
        let step3 = try XCTUnwrap(trailing2.slicingMetadata(at: stepMeters * 2))
        let trailing3 = step3.trailingLineString
        XCTAssertEqual(trailing3.coordinates.count, 2)
    }
}
