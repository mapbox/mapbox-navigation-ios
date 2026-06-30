@testable import MapboxDirections
import XCTest

class RouteNotificationTests: XCTestCase {
    func testDecodeViolationWithRange() throws {
        let json = """
        {
            "type": "violation",
            "subtype": "maxHeight",
            "refresh_type": "static",
            "geometry_index_start": 3,
            "geometry_index_end": 5,
            "details": {
                "actual_value": "4.60",
                "requested_value": "4.70",
                "unit": "meters",
                "message": "The height of the vehicle exceeds the road limit."
            }
        }
        """.data(using: .utf8)!

        let notification = try JSONDecoder().decode(RouteNotification.self, from: json)

        XCTAssertEqual(notification.kind, .violation)
        XCTAssertEqual(notification.subtype, .maxHeight)
        XCTAssertEqual(notification.refreshType, .static)
        XCTAssertEqual(notification.geometryIndexStart, 3)
        XCTAssertEqual(notification.geometryIndexEnd, 5)
        XCTAssertNil(notification.geometryIndex)
        XCTAssertEqual(notification.details?.actualValue, "4.60")
        XCTAssertEqual(notification.details?.requestedValue, "4.70")
        XCTAssertEqual(notification.details?.unit, "meters")
        XCTAssertEqual(notification.details?.message, "The height of the vehicle exceeds the road limit.")
    }

    func testDecodeAlertWithPointIndex() throws {
        let json = """
        {
            "type": "alert",
            "subtype": "stationUnavailable",
            "refresh_type": "dynamic",
            "geometry_index": 7,
            "reason": "outOfOrder",
            "station_id": "station-42"
        }
        """.data(using: .utf8)!

        let notification = try JSONDecoder().decode(RouteNotification.self, from: json)

        XCTAssertEqual(notification.kind, .alert)
        XCTAssertEqual(notification.subtype, .stationUnavailable)
        XCTAssertEqual(notification.refreshType, .dynamic)
        XCTAssertEqual(notification.geometryIndex, 7)
        XCTAssertNil(notification.geometryIndexStart)
        XCTAssertNil(notification.geometryIndexEnd)
        XCTAssertEqual(notification.reason, "outOfOrder")
        XCTAssertEqual(notification.stationId, "station-42")
    }

    func testDecodeNotificationWithoutGeometryIndex() throws {
        let json = """
        {
            "type": "violation",
            "subtype": "evMinChargeAtDestination",
            "refresh_type": "dynamic",
            "details": {
                "requested_value": "20000",
                "actual_value": "13000",
                "unit": "Wh"
            }
        }
        """.data(using: .utf8)!

        let notification = try JSONDecoder().decode(RouteNotification.self, from: json)

        XCTAssertEqual(notification.kind, .violation)
        XCTAssertEqual(notification.subtype, .evMinChargeAtDestination)
        XCTAssertNil(notification.geometryIndex)
        XCTAssertNil(notification.geometryIndexStart)
        XCTAssertNil(notification.geometryIndexEnd)
        XCTAssertNil(notification.stationId)
        XCTAssertNil(notification.reason)
        XCTAssertEqual(notification.details?.requestedValue, "20000")
        XCTAssertEqual(notification.details?.actualValue, "13000")
        XCTAssertEqual(notification.details?.unit, "Wh")
        XCTAssertNil(notification.details?.message)
    }

    func testUnknownTypePreservedInRawValue() throws {
        let json = """
        { "type": "brand_new_type", "refresh_type": "static" }
        """.data(using: .utf8)!

        let notification = try JSONDecoder().decode(RouteNotification.self, from: json)

        XCTAssertEqual(notification.kind.rawValue, "brand_new_type")
        XCTAssertNotEqual(notification.kind, .violation)
        XCTAssertNotEqual(notification.kind, .alert)
    }

    func testUnknownSubtypePreservedInRawValue() throws {
        let json = """
        { "type": "alert", "subtype": "futureSubtype", "refresh_type": "dynamic" }
        """.data(using: .utf8)!

        let notification = try JSONDecoder().decode(RouteNotification.self, from: json)

        XCTAssertEqual(notification.subtype?.rawValue, "futureSubtype")
        XCTAssertNotEqual(notification.subtype, .stationUnavailable)
        XCTAssertNotEqual(notification.subtype, .evInsufficientCharge)
    }

    func testUnknownRefreshTypePreservedInRawValue() throws {
        let json = """
        { "type": "alert", "refresh_type": "live" }
        """.data(using: .utf8)!

        let notification = try JSONDecoder().decode(RouteNotification.self, from: json)

        XCTAssertEqual(notification.refreshType?.rawValue, "live")
        XCTAssertNotEqual(notification.refreshType, .static)
        XCTAssertNotEqual(notification.refreshType, .dynamic)
    }

    func testEncodeDecodeRoundTrip() throws {
        let original = RouteNotification(
            kind: .violation,
            subtype: .maxWidth,
            refreshType: .static,
            geometryIndexStart: 1,
            geometryIndexEnd: 4,
            details: .init(
                requestedValue: "3.0",
                actualValue: "2.5",
                unit: "meters",
                message: "The width of the vehicle exceeds the road limit."
            )
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RouteNotification.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.kind, .violation)
        XCTAssertEqual(decoded.subtype, .maxWidth)
        XCTAssertEqual(decoded.refreshType, .static)
        XCTAssertEqual(decoded.geometryIndexStart, 1)
        XCTAssertEqual(decoded.geometryIndexEnd, 4)
        XCTAssertNil(decoded.geometryIndex)
        XCTAssertEqual(decoded.details?.requestedValue, "3.0")
        XCTAssertEqual(decoded.details?.actualValue, "2.5")
        XCTAssertEqual(decoded.details?.unit, "meters")
    }

    func testRouteLegNotificationsDecoding() throws {
        let json = """
        {
            "summary": "Main St",
            "distance": 500.0,
            "duration": 60.0,
            "steps": [],
            "notifications": [
                {
                    "type": "violation",
                    "subtype": "tunnel",
                    "refresh_type": "static",
                    "geometry_index_start": 2,
                    "geometry_index_end": 6,
                    "details": { "message": "Tunnel avoidance not possible." }
                },
                {
                    "type": "alert",
                    "subtype": "countryBorderCrossing",
                    "refresh_type": "static",
                    "geometry_index_start": 0,
                    "geometry_index_end": 1,
                    "details": { "actual_value": "US,CA", "message": "Crossing the border of the countries of US and CA." }
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

        let first = try XCTUnwrap(leg.notifications?.first)
        XCTAssertEqual(first.kind, .violation)
        XCTAssertEqual(first.subtype, .tunnel)
        XCTAssertEqual(first.refreshType, .static)
        XCTAssertEqual(first.geometryIndexStart, 2)
        XCTAssertEqual(first.geometryIndexEnd, 6)
        XCTAssertEqual(first.details?.message, "Tunnel avoidance not possible.")

        let second = try XCTUnwrap(leg.notifications?.last)
        XCTAssertEqual(second.kind, .alert)
        XCTAssertEqual(second.subtype, .countryBorderCrossing)
        XCTAssertEqual(second.details?.actualValue, "US,CA")
    }

    func testDecodingFailsWhenTypeMissing() throws {
        let json = "{}".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(RouteNotification.self, from: json))
    }

    func testRouteLegWithNoNotificationsDecodesAsNil() throws {
        let json = """
        {
            "summary": "Main St",
            "distance": 500.0,
            "duration": 60.0,
            "steps": []
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

        XCTAssertNil(leg.notifications)
    }
}
