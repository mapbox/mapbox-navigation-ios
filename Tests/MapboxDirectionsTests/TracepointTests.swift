@testable import MapboxDirections
import XCTest

final class TracepointTests: XCTestCase {
    func testCodingIfAllProperties() {
        let json = [
            "matchings_index": 0,
            "waypoint_index": 1,
            "alternatives_count": 2,
            "name": "Name",
            "location": [
                -122.030166,
                37.333761,
            ],
        ] as [String: Any?]

        let data = try! JSONSerialization.data(withJSONObject: json, options: [])
        var tracepoint: Match.Tracepoint?
        XCTAssertNoThrow(tracepoint = try JSONDecoder().decode(Match.Tracepoint.self, from: data))
        guard let tracepoint else {
            XCTFail("Should decode non nil tracepoint")
            return
        }

        XCTAssertEqual(tracepoint.matchingIndex, 0)
        XCTAssertEqual(tracepoint.waypointIndex, 1)
        XCTAssertEqual(tracepoint.countOfAlternatives, 2)
        XCTAssertEqual(tracepoint.name, "Name")
        XCTAssertEqual(tracepoint.coordinate, LocationCoordinate2D(latitude: 37.333761, longitude: -122.030166))

        let encoder = JSONEncoder()
        var encodedData: Data?
        XCTAssertNoThrow(encodedData = try encoder.encode(tracepoint))
        XCTAssertNotNil(encodedData)

        var encodedJSON: Any?
        XCTAssertNoThrow(encodedJSON = try JSONSerialization.jsonObject(with: encodedData!, options: []))
        XCTAssertNotNil(encodedJSON)
        XCTAssert(JSONSerialization.objectsAreEqual(json, encodedJSON, approximate: false))
    }

    func testCodingIfOptionalProperties() {
        let json = [
            "matchings_index": 0,
            "waypoint_index": nil,
            "alternatives_count": 2,
            "name": nil,
            "location": [
                -122.030166,
                37.333761,
            ],
        ] as [String: Any?]

        let data = try! JSONSerialization.data(withJSONObject: json, options: [])
        var tracepoint: Match.Tracepoint?
        XCTAssertNoThrow(tracepoint = try JSONDecoder().decode(Match.Tracepoint.self, from: data))
        guard let tracepoint else {
            XCTFail("Should decode non nil tracepoint")
            return
        }

        XCTAssertEqual(tracepoint.matchingIndex, 0)
        XCTAssertNil(tracepoint.waypointIndex)
        XCTAssertEqual(tracepoint.countOfAlternatives, 2)
        XCTAssertNil(tracepoint.name)
        XCTAssertEqual(tracepoint.coordinate, LocationCoordinate2D(latitude: 37.333761, longitude: -122.030166))

        let encoder = JSONEncoder()
        var encodedData: Data?
        XCTAssertNoThrow(encodedData = try encoder.encode(tracepoint))
        XCTAssertNotNil(encodedData)

        var encodedJSON: Any?
        XCTAssertNoThrow(encodedJSON = try JSONSerialization.jsonObject(with: encodedData!, options: []))
        XCTAssertNotNil(encodedJSON)
        XCTAssert(JSONSerialization.objectsAreEqual(json, encodedJSON, approximate: false))
    }
}
