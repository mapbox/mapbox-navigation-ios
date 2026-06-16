@testable import MapboxDirections
import XCTest

final class IncidentTests: XCTestCase {
    private var encoder: JSONEncoder!

    override func setUp() {
        super.setUp()
        encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
    }

    // MARK: - Coding

    func testIncidentsDecoding() throws {
        let json = """
        [
            {
                "id": "12727074056824787215",
                "type": "miscellaneous",
                "description": "Bei Windach - Verkehrsbehinderung.",
                "long_description": "Bei Windach - Verkehrsbehinderung. A96 Lindau Richtung München in Höhe Windach Grünpflege, bis 04.11.2020 15:00 Uhr",
                "creation_time": "2020-11-04T09:51:00Z",
                "start_time": "2020-11-04T07:07:50Z",
                "end_time": "2020-11-04T14:00:00Z",
                "impact": "minor",
                "alertc_codes": [],
                "lanes_blocked": ["RIGHT", "SIDE"],
                "geometry_index_start": 353,
                "geometry_index_end": 367,
                "iso_3166_1_alpha3": "DEU",
                "iso_3166_1_alpha2": "DE",
                "closed": false,
                "num_lanes_blocked": 2,
                "congestion": { "value": 50 },
                "affected_road_names": ["A96", "test"]
            },
            {
                "id": "12779545487967908590",
                "type": "construction",
                "description": "Description 1",
                "long_description": "Long description 1",
                "creation_time": "2020-11-04T09:51:00Z",
                "start_time": "2020-07-03T17:00:00Z",
                "end_time": "2020-12-08T04:30:00Z",
                "impact": "minor",
                "sub_type": "CONSTRUCTION",
                "sub_type_description": "construction",
                "alertc_codes": [701],
                "geometry_index_start": 476,
                "geometry_index_end": 566,
                "closed": true
            },
            {
                "id": "2113169574233653303",
                "type": "construction",
                "description": "Description 2",
                "long_description": "Long description 2",
                "creation_time": "2020-11-04T09:51:00Z",
                "start_time": "2020-10-23T08:23:32Z",
                "end_time": "2020-11-27T16:00:00Z",
                "impact": "minor",
                "sub_type": "CONSTRUCTION",
                "sub_type_description": "construction",
                "alertc_codes": [803],
                "lanes_blocked": ["unknown lane type"],
                "geometry_index_start": 810,
                "geometry_index_end": 900,
                "num_lanes_blocked": 1
            }
        ]
        """.data(using: .utf8)!

        let incidents = try JSONDecoder().decode([Incident].self, from: json)
        XCTAssertEqual(incidents.count, 3)

        let isoFormatter = ISO8601DateFormatter()

        let first = incidents[0]
        XCTAssertEqual(first.identifier, "12727074056824787215")
        XCTAssertEqual(first.rawKind, "miscellaneous")
        XCTAssertEqual(first.kind, .miscellaneous)
        XCTAssertEqual(first.description, "Bei Windach - Verkehrsbehinderung.")
        XCTAssertEqual(
            first.longDescription,
            "Bei Windach - Verkehrsbehinderung. A96 Lindau Richtung München in Höhe Windach Grünpflege, bis 04.11.2020 15:00 Uhr"
        )
        XCTAssertEqual(first.impact, .minor)
        XCTAssertNil(first.subtype)
        XCTAssertNil(first.subtypeDescription)
        XCTAssertEqual(first.alertCodes, [])
        XCTAssertEqual(first.lanesBlocked, [.right, .side])
        XCTAssertEqual(first.shapeIndexRange, 353..<367)
        XCTAssertEqual(first.countryCodeAlpha3, "DEU")
        XCTAssertEqual(first.countryCode, "DE")
        XCTAssertEqual(first.roadIsClosed, false)
        XCTAssertEqual(first.numberOfBlockedLanes, 2)
        XCTAssertEqual(first.congestionLevel, 50)
        XCTAssertEqual(first.affectedRoadNames, ["A96", "test"])
        XCTAssertEqual(first.creationDate, isoFormatter.date(from: "2020-11-04T09:51:00Z"))
        XCTAssertEqual(first.startDate, isoFormatter.date(from: "2020-11-04T07:07:50Z"))
        XCTAssertEqual(first.endDate, isoFormatter.date(from: "2020-11-04T14:00:00Z"))

        let second = incidents[1]
        XCTAssertEqual(second.identifier, "12779545487967908590")
        XCTAssertEqual(second.rawKind, "construction")
        XCTAssertEqual(second.kind, .construction)
        XCTAssertEqual(second.description, "Description 1")
        XCTAssertEqual(second.longDescription, "Long description 1")
        XCTAssertEqual(second.impact, .minor)
        XCTAssertEqual(second.subtype, "CONSTRUCTION")
        XCTAssertEqual(second.subtypeDescription, "construction")
        XCTAssertEqual(second.alertCodes, [701])
        XCTAssertNil(second.lanesBlocked)
        XCTAssertEqual(second.shapeIndexRange, 476..<566)
        XCTAssertEqual(second.roadIsClosed, true)
        XCTAssertNil(second.congestionLevel)
        XCTAssertNil(second.affectedRoadNames)
        XCTAssertEqual(second.creationDate, isoFormatter.date(from: "2020-11-04T09:51:00Z"))
        XCTAssertEqual(second.startDate, isoFormatter.date(from: "2020-07-03T17:00:00Z"))
        XCTAssertEqual(second.endDate, isoFormatter.date(from: "2020-12-08T04:30:00Z"))

        let third = incidents[2]
        XCTAssertEqual(third.identifier, "2113169574233653303")
        XCTAssertEqual(third.rawKind, "construction")
        XCTAssertEqual(third.kind, .construction)
        XCTAssertEqual(third.description, "Description 2")
        XCTAssertEqual(third.longDescription, "Long description 2")
        XCTAssertEqual(third.impact, .minor)
        XCTAssertEqual(third.subtype, "CONSTRUCTION")
        XCTAssertEqual(third.subtypeDescription, "construction")
        XCTAssertEqual(third.alertCodes, [803])
        XCTAssertEqual(third.lanesBlocked, BlockedLanes(rawValue: 0))
        XCTAssertEqual(third.shapeIndexRange, 810..<900)
        XCTAssertNil(third.countryCodeAlpha3)
        XCTAssertNil(third.countryCode)
        XCTAssertNil(third.roadIsClosed)
        XCTAssertEqual(third.numberOfBlockedLanes, 1)
        XCTAssertNil(third.congestionLevel)
        XCTAssertNil(third.affectedRoadNames)
        XCTAssertEqual(third.creationDate, isoFormatter.date(from: "2020-11-04T09:51:00Z"))
        XCTAssertEqual(third.startDate, isoFormatter.date(from: "2020-10-23T08:23:32Z"))
        XCTAssertEqual(third.endDate, isoFormatter.date(from: "2020-11-27T16:00:00Z"))
    }

    func testIncidentEncoding() throws {
        let isoFormatter = ISO8601DateFormatter()
        let incident = Incident(
            identifier: "test_id",
            type: .accident,
            description: "Test accident",
            creationDate: isoFormatter.date(from: "2021-01-01T10:00:00Z")!,
            startDate: isoFormatter.date(from: "2021-01-01T09:00:00Z")!,
            endDate: isoFormatter.date(from: "2021-01-01T12:00:00Z")!,
            impact: .major,
            subtype: "REAR_END",
            subtypeDescription: "Rear end collision",
            alertCodes: [101, 202],
            lanesBlocked: [.left, .center],
            shapeIndexRange: 10..<20,
            countryCodeAlpha3: "USA",
            countryCode: "US",
            roadIsClosed: true,
            longDescription: "A major accident blocking left and center lanes.",
            numberOfBlockedLanes: 2,
            congestionLevel: 75,
            affectedRoadNames: ["I-95", "Highway 1"]
        )

        let data = try encoder.encode(incident)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["id"] as? String, "test_id")
        XCTAssertEqual(json["type"] as? String, "accident")
        XCTAssertEqual(json["description"] as? String, "Test accident")
        XCTAssertEqual(json["creation_time"] as? String, "2021-01-01T10:00:00Z")
        XCTAssertEqual(json["start_time"] as? String, "2021-01-01T09:00:00Z")
        XCTAssertEqual(json["end_time"] as? String, "2021-01-01T12:00:00Z")
        XCTAssertEqual(json["impact"] as? String, "major")
        XCTAssertEqual(json["sub_type"] as? String, "REAR_END")
        XCTAssertEqual(json["sub_type_description"] as? String, "Rear end collision")
        XCTAssertEqual(Set(json["alertc_codes"] as! [Int]), [101, 202])
        XCTAssertEqual(Set(json["lanes_blocked"] as! [String]), ["LEFT", "CENTER"])
        XCTAssertEqual(json["geometry_index_start"] as? Int, 10)
        XCTAssertEqual(json["geometry_index_end"] as? Int, 20)
        XCTAssertEqual(json["iso_3166_1_alpha3"] as? String, "USA")
        XCTAssertEqual(json["iso_3166_1_alpha2"] as? String, "US")
        XCTAssertEqual(json["closed"] as? Bool, true)
        XCTAssertEqual(json["long_description"] as? String, "A major accident blocking left and center lanes.")
        XCTAssertEqual(json["num_lanes_blocked"] as? Int, 2)
        XCTAssertEqual((json["congestion"] as? [String: Int])?["value"], 75)
        XCTAssertEqual(json["affected_road_names"] as? [String], ["I-95", "Highway 1"])
    }

    func testIncidentEncodingAndDecoding() throws {
        let isoFormatter = ISO8601DateFormatter()
        let original = Incident(
            identifier: "roundtrip_id",
            type: .roadClosure,
            description: "Road closure test",
            creationDate: isoFormatter.date(from: "2021-06-15T08:00:00Z")!,
            startDate: isoFormatter.date(from: "2021-06-15T07:00:00Z")!,
            endDate: isoFormatter.date(from: "2021-06-15T18:00:00Z")!,
            impact: .critical,
            subtype: nil,
            subtypeDescription: nil,
            alertCodes: [500],
            lanesBlocked: [.left, .right],
            shapeIndexRange: 5..<15,
            countryCodeAlpha3: "GBR",
            countryCode: "GB",
            roadIsClosed: true,
            longDescription: "Full road closure.",
            numberOfBlockedLanes: 2,
            congestionLevel: 90,
            affectedRoadNames: ["M25"]
        )

        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(Incident.self, from: data)

        XCTAssertEqual(decoded.identifier, original.identifier)
        XCTAssertEqual(decoded.rawKind, original.rawKind)
        XCTAssertEqual(decoded.kind, original.kind)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.creationDate, original.creationDate)
        XCTAssertEqual(decoded.startDate, original.startDate)
        XCTAssertEqual(decoded.endDate, original.endDate)
        XCTAssertEqual(decoded.impact, original.impact)
        XCTAssertEqual(decoded.subtype, original.subtype)
        XCTAssertEqual(decoded.subtypeDescription, original.subtypeDescription)
        XCTAssertEqual(decoded.alertCodes, original.alertCodes)
        XCTAssertEqual(decoded.lanesBlocked, original.lanesBlocked)
        XCTAssertEqual(decoded.shapeIndexRange, original.shapeIndexRange)
        XCTAssertEqual(decoded.countryCodeAlpha3, original.countryCodeAlpha3)
        XCTAssertEqual(decoded.countryCode, original.countryCode)
        XCTAssertEqual(decoded.roadIsClosed, original.roadIsClosed)
        XCTAssertEqual(decoded.longDescription, original.longDescription)
        XCTAssertEqual(decoded.numberOfBlockedLanes, original.numberOfBlockedLanes)
        XCTAssertEqual(decoded.congestionLevel, original.congestionLevel)
        XCTAssertEqual(decoded.affectedRoadNames, original.affectedRoadNames)
    }

    // MARK: - Nil fields

    func testUnknownIncidentKindReturnsNilKind() throws {
        let data = try makeIncidentData(overriding: ["type": "totally_unknown_type"])
        let incident = try JSONDecoder().decode(Incident.self, from: data)
        XCTAssertEqual(incident.rawKind, "totally_unknown_type")
        XCTAssertNil(incident.kind)
    }

    func testCongestionUnavailableValueDecodesToNil() throws {
        let data = try makeIncidentData(overriding: ["congestion": ["value": 101]])
        let incident = try JSONDecoder().decode(Incident.self, from: data)
        XCTAssertNil(incident.congestionLevel)
    }

    func testOptionalFieldsAbsent() throws {
        let data = try makeIncidentData()
        let incident = try JSONDecoder().decode(Incident.self, from: data)
        XCTAssertNil(incident.impact)
        XCTAssertNil(incident.subtype)
        XCTAssertNil(incident.subtypeDescription)
        XCTAssertNil(incident.lanesBlocked)
        XCTAssertNil(incident.countryCodeAlpha3)
        XCTAssertNil(incident.countryCode)
        XCTAssertNil(incident.roadIsClosed)
        XCTAssertNil(incident.longDescription)
        XCTAssertNil(incident.numberOfBlockedLanes)
        XCTAssertNil(incident.congestionLevel)
        XCTAssertNil(incident.affectedRoadNames)
    }

    func testDecodingSucceedsWhenMissingAlertCodes() throws {
        let data = try makeIncidentData(overriding: ["alertc_codes": nil])
        let incident = try JSONDecoder().decode(Incident.self, from: data)
        XCTAssertEqual(incident.alertCodes, [])
    }

    func testDecodingFailsWhenMissingIdentifier() throws {
        let data = try makeIncidentData(overriding: ["id": nil])
        XCTAssertThrowsError(try JSONDecoder().decode(Incident.self, from: data))
    }

    func testDecodingFailsWhenMissingType() throws {
        let data = try makeIncidentData(overriding: ["type": nil])
        XCTAssertThrowsError(try JSONDecoder().decode(Incident.self, from: data))
    }

    func testDecodingFailsWhenMissingDescription() throws {
        let data = try makeIncidentData(overriding: ["description": nil])
        XCTAssertThrowsError(try JSONDecoder().decode(Incident.self, from: data))
    }

    func testDecodingFailsWhenMissingCreationTime() throws {
        let data = try makeIncidentData(overriding: ["creation_time": nil])
        XCTAssertThrowsError(try JSONDecoder().decode(Incident.self, from: data))
    }

    func testDecodingFailsWhenMissingStartTime() throws {
        let data = try makeIncidentData(overriding: ["start_time": nil])
        XCTAssertThrowsError(try JSONDecoder().decode(Incident.self, from: data))
    }

    func testDecodingFailsWhenMissingEndTime() throws {
        let data = try makeIncidentData(overriding: ["end_time": nil])
        XCTAssertThrowsError(try JSONDecoder().decode(Incident.self, from: data))
    }

    func testDecodingFailsWhenMissingGeometryIndexStart() throws {
        let data = try makeIncidentData(overriding: ["geometry_index_start": nil])
        XCTAssertThrowsError(try JSONDecoder().decode(Incident.self, from: data))
    }

    func testDecodingFailsWhenMissingGeometryIndexEnd() throws {
        let data = try makeIncidentData(overriding: ["geometry_index_end": nil])
        XCTAssertThrowsError(try JSONDecoder().decode(Incident.self, from: data))
    }

    func testDecodingSucceedsWhenGeometryIndexRangeIsEmpty() throws {
        let data = try makeIncidentData(overriding: [
            "geometry_index_start": 5,
            "geometry_index_end": 5,
        ])
        let incident = try JSONDecoder().decode(Incident.self, from: data)
        XCTAssertEqual(incident.shapeIndexRange, 5..<5)
    }

    func testDecodingFailsWhenGeometryIndexRangeIsInverted() throws {
        let data = try makeIncidentData(overriding: [
            "geometry_index_start": 5,
            "geometry_index_end": 0,
        ])
        XCTAssertThrowsError(try JSONDecoder().decode(Incident.self, from: data))
    }

    func testDecodingFailsWhenGeometryIndexRangeIsNegative() throws {
        let data = try makeIncidentData(overriding: [
            "geometry_index_start": -1,
            "geometry_index_end": 0,
        ])
        XCTAssertThrowsError(try JSONDecoder().decode(Incident.self, from: data))
    }

    func testDecodingFailsWhenStartTimeHasInvalidFormat() throws {
        let data = try makeIncidentData(overriding: ["start_time": "not-a-date"])
        XCTAssertThrowsError(try JSONDecoder().decode(Incident.self, from: data))
    }

    func testDecodingFailsWhenEndTimeHasInvalidFormat() throws {
        let data = try makeIncidentData(overriding: ["end_time": "not-a-date"])
        XCTAssertThrowsError(try JSONDecoder().decode(Incident.self, from: data))
    }

    func testDecodingFailsWhenCreationTimeHasInvalidFormat() throws {
        let data = try makeIncidentData(overriding: ["creation_time": "not-a-date"])
        XCTAssertThrowsError(try JSONDecoder().decode(Incident.self, from: data))
    }

    // MARK: - Helpers

    private func makeIncidentData(overriding overrides: [String: Any?] = [:]) throws -> Data {
        var dictionary: [String: Any] = [
            "id": "test_id",
            "type": "accident",
            "description": "Test description",
            "creation_time": "2021-01-01T10:00:00Z",
            "start_time": "2021-01-01T09:00:00Z",
            "end_time": "2021-01-01T12:00:00Z",
            "alertc_codes": [Int](),
            "geometry_index_start": 0,
            "geometry_index_end": 5,
        ]
        for (key, value) in overrides {
            if let value {
                dictionary[key] = value
            } else {
                dictionary.removeValue(forKey: key)
            }
        }
        return try JSONSerialization.data(withJSONObject: dictionary)
    }
}
