import XCTest
#if !os(Linux)
import CoreLocation
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif
@testable import MapboxDirections
import OHHTTPStubs

class AnnotationTests: XCTestCase {
    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    @MainActor
    func testAnnotation() {
        let expectation = expectation(description: "calculating directions should return results")

        let queryParams: [String: String?] = [
            "alternatives": "false",
            "geometries": "polyline",
            "overview": "full",
            "steps": "false",
            "continue_straight": "true",
            "access_token": BogusToken,
            "annotations": "distance,duration,speed,congestion,maxspeed,congestion_numeric",
        ]

        stub(
            condition: isHost("api.mapbox.com") && containsQueryParams(queryParams)
        ) { _ in
            let path = Bundle.module.path(forResource: "annotation", ofType: "json")
            return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        let options = RouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 37.780602, longitude: -122.431373),
            CLLocationCoordinate2D(latitude: 37.758859, longitude: -122.404058),
        ], profileIdentifier: .automobileAvoidingTraffic)
        options.shapeFormat = .polyline
        options.includesSteps = false
        options.includesAlternativeRoutes = false
        options.routeShapeResolution = .full
        options.attributeOptions = [
            .distance,
            .expectedTravelTime,
            .speed,
            .congestionLevel,
            .numericCongestionLevel,
            .maximumSpeedLimit,
        ]
        var route: Route?
        let task = Directions(credentials: BogusCredentials).calculate(options) { disposition in
            switch disposition {
            case .failure(let error):
                XCTFail("Error! \(error)")
            case .success(let response):
                XCTAssertNotNil(response.routes)
                XCTAssertEqual(response.routes!.count, 1)
                let _route = response.routes!.first!
                Task { @MainActor in
                    route = _route
                    expectation.fulfill()
                }
            }
        }
        XCTAssertNotNil(task)

        waitForExpectations(timeout: 8) { error in
            XCTAssertNil(error, "Error: \(error!.localizedDescription)")
            XCTAssertEqual(task.state, .completed)
        }

        XCTAssertNotNil(route)
        if let route {
            XCTAssertNotNil(route.shape)
            XCTAssertEqual(route.shape?.coordinates.count, 154)
            XCTAssertEqual(route.legs.count, 1)
        }

        if let leg = route?.legs.first {
            XCTAssertEqual(leg.segmentDistances?.count, 153)
            XCTAssertEqual(leg.segmentSpeeds?.count, 153)
            XCTAssertEqual(leg.expectedSegmentTravelTimes?.count, 153)

            XCTAssertEqual(leg.segmentCongestionLevels?.count, 153)
            XCTAssertEqual(leg.segmentCongestionLevels?.firstIndex(of: .unknown), 2)
            XCTAssertEqual(leg.segmentCongestionLevels?.firstIndex(of: .low), 0)
            XCTAssertEqual(leg.segmentCongestionLevels?.firstIndex(of: .moderate), 14)
            XCTAssertFalse(leg.segmentCongestionLevels?.contains(.heavy) ?? true)
            XCTAssertFalse(leg.segmentCongestionLevels?.contains(.severe) ?? true)

            XCTAssertEqual(leg.segmentNumericCongestionLevels?.count, 153)
            XCTAssertEqual(leg.segmentNumericCongestionLevels?.firstIndex(of: nil), 2)
            XCTAssertEqual(leg.segmentNumericCongestionLevels?.firstIndex(of: 12), 91)
            XCTAssertEqual(leg.segmentNumericCongestionLevels?.firstIndex(of: 32), 60)
            XCTAssertFalse(leg.segmentNumericCongestionLevels?.contains(26) ?? true)

            XCTAssertEqual(leg.segmentMaximumSpeedLimits?.count, 153)
            XCTAssertEqual(leg.segmentMaximumSpeedLimits?.first, Measurement(value: 48, unit: .kilometersPerHour))
            XCTAssertEqual(leg.segmentMaximumSpeedLimits?.firstIndex(of: nil), 2)
            XCTAssertFalse(leg.segmentMaximumSpeedLimits?.contains(Measurement(
                value: .infinity,
                unit: .kilometersPerHour
            )) ?? true)
        }
    }

    func testSpeedLimits() {
        func assert(
            _ speedLimitDescriptorJSON: [String: Any],
            roundTripsWith expectedSpeedLimitDescriptor: SpeedLimitDescriptor
        ) {
            let speedLimitDescriptorData = try! JSONSerialization.data(
                withJSONObject: speedLimitDescriptorJSON,
                options: []
            )
            var speedLimitDescriptor: SpeedLimitDescriptor?
            XCTAssertNoThrow(speedLimitDescriptor = try JSONDecoder().decode(
                SpeedLimitDescriptor.self,
                from: speedLimitDescriptorData
            ))
            XCTAssertEqual(speedLimitDescriptor, expectedSpeedLimitDescriptor)

            speedLimitDescriptor = expectedSpeedLimitDescriptor

            let encoder = JSONEncoder()
            var encodedData: Data?
            XCTAssertNoThrow(encodedData = try encoder.encode(speedLimitDescriptor))
            XCTAssertNotNil(encodedData)
            if let encodedData {
                var encodedSpeedLimitDescriptorJSON: [String: Any?]?
                XCTAssertNoThrow(encodedSpeedLimitDescriptorJSON = try JSONSerialization.jsonObject(
                    with: encodedData,
                    options: []
                ) as? [String: Any?])
                XCTAssertNotNil(encodedSpeedLimitDescriptorJSON)

                XCTAssert(JSONSerialization.objectsAreEqual(
                    speedLimitDescriptorJSON,
                    encodedSpeedLimitDescriptorJSON,
                    approximate: true
                ))
            }
        }

        XCTAssertEqual(
            SpeedLimitDescriptor(speed: Measurement(value: 55, unit: .milesPerHour)),
            .some(speed: Measurement(value: 55, unit: .milesPerHour))
        )
        XCTAssertEqual(
            Measurement<UnitSpeed>(speedLimitDescriptor: .some(speed: Measurement(value: 55, unit: .milesPerHour))),
            Measurement(value: 55, unit: .milesPerHour)
        )
        assert(
            ["speed": 55.0, "unit": "mph"],
            roundTripsWith: .some(speed: Measurement(value: 55, unit: .milesPerHour))
        )

        XCTAssertEqual(
            SpeedLimitDescriptor(speed: Measurement(value: 80, unit: .kilometersPerHour)),
            .some(speed: Measurement(value: 80, unit: .kilometersPerHour))
        )
        XCTAssertEqual(
            Measurement<UnitSpeed>(speedLimitDescriptor: .some(speed: Measurement(
                value: 80,
                unit: .kilometersPerHour
            ))),
            Measurement(value: 80, unit: .kilometersPerHour)
        )
        assert(
            ["speed": 80.0, "unit": "km/h"],
            roundTripsWith: .some(speed: Measurement(value: 80, unit: .kilometersPerHour))
        )

        XCTAssertEqual(SpeedLimitDescriptor(speed: nil), .unknown)
        XCTAssertNil(Measurement<UnitSpeed>(speedLimitDescriptor: .unknown))
        assert(["unknown": true], roundTripsWith: .unknown)

        XCTAssertEqual(SpeedLimitDescriptor(speed: Measurement(value: .infinity, unit: .kilometersPerHour)), .none)
        XCTAssertEqual(
            Measurement<UnitSpeed>(speedLimitDescriptor: .none),
            Measurement(value: .infinity, unit: .kilometersPerHour)
        )
        assert(["none": true], roundTripsWith: .none)
    }
}
#endif
