@testable import MapboxDirections
import Turf
import XCTest

class RouteLegTests: XCTestCase {
    func testSegmentRanges() {
        var departureStep = RouteStep(
            transportType: .automobile,
            maneuverLocation: LocationCoordinate2D(latitude: 0, longitude: 0),
            maneuverType: .depart,
            instructions: "Depart",
            drivingSide: .right,
            distance: 10,
            expectedTravelTime: 10
        )
        departureStep.shape = LineString([
            LocationCoordinate2D(latitude: 0, longitude: 0),
            LocationCoordinate2D(latitude: 1, longitude: 1),
        ])
        let noShapeStep = RouteStep(
            transportType: .automobile,
            maneuverLocation: LocationCoordinate2D(latitude: 1, longitude: 1),
            maneuverType: .continue,
            instructions: "Continue",
            drivingSide: .right,
            distance: 0,
            expectedTravelTime: 0
        )
        var turnStep = RouteStep(
            transportType: .automobile,
            maneuverLocation: LocationCoordinate2D(latitude: 1, longitude: 1),
            maneuverType: .turn,
            maneuverDirection: .left,
            instructions: "Turn left at Albuquerque",
            drivingSide: .right,
            distance: 10,
            expectedTravelTime: 10
        )
        turnStep.shape = LineString([
            LocationCoordinate2D(latitude: 1, longitude: 1),
            LocationCoordinate2D(latitude: 2, longitude: 2),
            LocationCoordinate2D(latitude: 3, longitude: 3),
            LocationCoordinate2D(latitude: 4, longitude: 4),
        ])
        let typicalTravelTime = 10.0
        var arrivalStep = RouteStep(
            transportType: .automobile,
            maneuverLocation: LocationCoordinate2D(latitude: 4, longitude: 4),
            maneuverType: .arrive,
            instructions: "Arrive at Elmer’s House",
            drivingSide: .right,
            distance: 0,
            expectedTravelTime: 0
        )
        arrivalStep.shape = LineString([
            LocationCoordinate2D(latitude: 4, longitude: 4),
            LocationCoordinate2D(latitude: 4, longitude: 4),
        ])
        var leg = RouteLeg(
            steps: [departureStep, noShapeStep, turnStep, arrivalStep],
            name: "",
            distance: 10,
            expectedTravelTime: 10,
            typicalTravelTime: typicalTravelTime,
            profileIdentifier: .automobile
        )
        leg.segmentDistances = [
            10,
            10, 20, 30,
        ]
        XCTAssertEqual(leg.segmentRangesByStep.count, leg.steps.count)
        XCTAssertEqual(leg.segmentRangesByStep, [0..<1, 1..<1, 1..<4, 4..<4])
        XCTAssertEqual(leg.segmentRangesByStep.last?.upperBound, leg.segmentDistances?.count)
        XCTAssertEqual(leg.typicalTravelTime, typicalTravelTime)
    }

    func testDecodeNotifications() throws {
        let json = """
        {
            "summary": "",
            "distance": 100,
            "duration": 60,
            "steps": [],
            "notifications": [
                {
                    "type": "violation",
                    "subtype": "maxHeight",
                    "refresh_type": "static",
                    "geometry_index_start": 0,
                    "geometry_index_end": 2,
                    "details": {
                        "actual_value": "3.0",
                        "requested_value": "4.0",
                        "unit": "meters",
                        "message": "The height of the vehicle exceeds the road limit."
                    }
                },
                {
                    "type": "alert",
                    "subtype": "stationUnavailable",
                    "refresh_type": "dynamic",
                    "geometry_index": 5,
                    "station_id": "station-7",
                    "reason": "occupied"
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.userInfo[.options] = RouteOptions(
            waypoints: [
                Waypoint(coordinate: .init(latitude: 0, longitude: 0)),
                Waypoint(coordinate: .init(latitude: 1, longitude: 1)),
            ],
            profileIdentifier: .automobileAvoidingTraffic
        )

        let leg = try decoder.decode(RouteLeg.self, from: json)

        XCTAssertEqual(leg.notifications?.count, 2)

        let violation = try XCTUnwrap(leg.notifications?.first)
        XCTAssertEqual(violation.kind, .violation)
        XCTAssertEqual(violation.subtype, .maxHeight)
        XCTAssertEqual(violation.refreshType, .static)
        XCTAssertEqual(violation.geometryIndexStart, 0)
        XCTAssertEqual(violation.geometryIndexEnd, 2)
        XCTAssertNil(violation.geometryIndex)
        XCTAssertEqual(violation.details?.actualValue, "3.0")
        XCTAssertEqual(violation.details?.requestedValue, "4.0")
        XCTAssertEqual(violation.details?.unit, "meters")
        XCTAssertEqual(violation.details?.message, "The height of the vehicle exceeds the road limit.")

        let alert = try XCTUnwrap(leg.notifications?.last)
        XCTAssertEqual(alert.kind, .alert)
        XCTAssertEqual(alert.subtype, .stationUnavailable)
        XCTAssertEqual(alert.refreshType, .dynamic)
        XCTAssertEqual(alert.geometryIndex, 5)
        XCTAssertNil(alert.geometryIndexStart)
        XCTAssertNil(alert.geometryIndexEnd)
        XCTAssertEqual(alert.stationId, "station-7")
        XCTAssertEqual(alert.reason, "occupied")
    }

    func testDecodingSucceeds() throws {
        let data = try makeRouteLegData()
        XCTAssertNoThrow(try makeRouteLegDecoder().decode(RouteLeg.self, from: data))
    }

    func testDecodingSucceedsWhenClosureGeometryIndexRangeIsEmpty() throws {
        let data = try makeRouteLegData(overriding: [
            "closures": [
                [
                    "geometry_index_start": 5,
                    "geometry_index_end": 5,
                ],
            ],
        ])
        let leg = try makeRouteLegDecoder().decode(RouteLeg.self, from: data)
        XCTAssertEqual(leg.closures?.first?.shapeIndexRange, 5..<5)
    }

    func testDecodingFailsWhenClosureGeometryIndexRangeIsInverted() throws {
        let data = try makeRouteLegData(overriding: [
            "closures": [
                [
                    "geometry_index_start": 5,
                    "geometry_index_end": 0,
                ],
            ],
        ])
        XCTAssertThrowsError(try makeRouteLegDecoder().decode(RouteLeg.self, from: data))
    }

    func testDecodingFailsWhenClosureGeometryIndexRangeIsNegative() throws {
        let data = try makeRouteLegData(overriding: [
            "closures": [
                [
                    "geometry_index_start": -1,
                    "geometry_index_end": 0,
                ],
            ],
        ])
        XCTAssertThrowsError(try makeRouteLegDecoder().decode(RouteLeg.self, from: data))
    }

    func testDecodingFailsWhenMissingSummary() throws {
        let data = try makeRouteLegData(overriding: ["summary": nil])
        XCTAssertThrowsError(try makeRouteLegDecoder().decode(RouteLeg.self, from: data))
    }

    func testDecodingFailsWhenMissingDistance() throws {
        let data = try makeRouteLegData(overriding: ["distance": nil])
        XCTAssertThrowsError(try makeRouteLegDecoder().decode(RouteLeg.self, from: data))
    }

    func testDecodingFailsWhenMissingDuration() throws {
        let data = try makeRouteLegData(overriding: ["duration": nil])
        XCTAssertThrowsError(try makeRouteLegDecoder().decode(RouteLeg.self, from: data))
    }

    func testDecodingFailsWhenMissingSteps() throws {
        let data = try makeRouteLegData(overriding: ["steps": nil])
        XCTAssertThrowsError(try makeRouteLegDecoder().decode(RouteLeg.self, from: data))
    }

    // MARK: - Helpers

    private func makeRouteLegDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = RouteOptions(
            waypoints: [
                Waypoint(coordinate: .init(latitude: 0, longitude: 0)),
                Waypoint(coordinate: .init(latitude: 1, longitude: 1)),
            ],
            profileIdentifier: .automobile
        )
        return decoder
    }

    private func makeRouteLegData(overriding overrides: [String: Any?] = [:]) throws -> Data {
        var dict: [String: Any] = [
            "summary": "Test Leg",
            "distance": 100.0,
            "duration": 60.0,
            "steps": [Any](),
        ]
        for (key, value) in overrides {
            if let value {
                dict[key] = value
            } else {
                dict.removeValue(forKey: key)
            }
        }
        return try JSONSerialization.data(withJSONObject: dict)
    }
}
