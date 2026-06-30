import XCTest
#if canImport(CoreLocation)
import CoreLocation
#endif
import Turf
#if !os(Linux)
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif
#endif
@testable import MapboxDirections

class MatchTests: XCTestCase {
    override func tearDown() {
#if !os(Linux)
        HTTPStubs.removeAllStubs()
#endif
        super.tearDown()
    }

#if !os(Linux)
    @MainActor
    func testMatch() throws {
        let expectation = expectation(description: "calculating directions should return results")
        let locations = [
            CLLocationCoordinate2D(latitude: 32.712041, longitude: -117.172836),
            CLLocationCoordinate2D(latitude: 32.712256, longitude: -117.17291),
            CLLocationCoordinate2D(latitude: 32.712444, longitude: -117.17292),
            CLLocationCoordinate2D(latitude: 32.71257, longitude: -117.172922),
            CLLocationCoordinate2D(latitude: 32.7126, longitude: -117.172985),
            CLLocationCoordinate2D(latitude: 32.712597, longitude: -117.173143),
            CLLocationCoordinate2D(latitude: 32.712546, longitude: -117.173345),
        ]

        stub(
            condition: isHost("api.mapbox.com")
                && isMethodGET()
                && pathStartsWith("/matching/v5/mapbox/driving")
        ) { _ in
            let path = Bundle.module.path(forResource: "match", ofType: "json")
            return HTTPStubsResponse(
                fileAtPath: path!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }

        var match: Match!
        var tracepoints: [Match.Tracepoint?]!
        let matchOptions = MatchOptions(coordinates: locations)
        matchOptions.includesSteps = true
        matchOptions.routeShapeResolution = .full

        let task = Directions(credentials: BogusCredentials).calculate(matchOptions) { result in
            guard case .success(let resp) = result else {
                XCTFail("Encountered unexpected error. \(result)")
                return
            }

            Task { @MainActor [m = resp.matches?.first, t = resp.tracepoints] in
                match = m
                tracepoints = t
                expectation.fulfill()
            }
        }
        XCTAssertNotNil(task)

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, .completed)
        }

        _ = try XCTUnwrap(match)
        _ = try XCTUnwrap(tracepoints)

        XCTAssertNotNil(match)
        XCTAssertNotNil(match.shape)
        XCTAssertEqual(match.shape!.coordinates.count, 18)

        XCTAssertEqual(tracepoints.first!!.countOfAlternatives, 0)
        XCTAssertEqual(tracepoints.last!!.name, "West G Street")

        // confirming actual decoded values is important because the Directions API
        // uses an atypical precision level for polyline encoding
        XCTAssertEqual(round(match.shape!.coordinates.first!.latitude), 33)
        XCTAssertEqual(round(match.shape!.coordinates.first!.longitude), -117)
        XCTAssertEqual(match.legs.count, 6)
        XCTAssertEqual(match.confidence, 0.95, accuracy: 1e-2)

        let leg = match.legs.first!
        XCTAssertEqual(leg.name, "North Harbor Drive")
        XCTAssertEqual(leg.steps.count, 2)

        let firstStep = leg.steps.first
        XCTAssertNotNil(firstStep)
        let firstStepIntersections = firstStep?.intersections
        XCTAssertNotNil(firstStepIntersections)
        let firstIntersection = firstStepIntersections?.first
        XCTAssertNotNil(firstIntersection)

        let step = leg.steps[0]
        XCTAssertEqual(round(step.distance), 25)
        XCTAssertEqual(round(step.expectedTravelTime), 3)
        XCTAssertEqual(step.instructions, "Head north on North Harbor Drive")

        XCTAssertEqual(step.maneuverType, .depart)
        XCTAssertEqual(step.maneuverDirection, .none)
        XCTAssertEqual(step.initialHeading, 0)
        XCTAssertEqual(step.finalHeading, 340)

        XCTAssertNotNil(step.shape?.coordinates)
        XCTAssertEqual(step.shape!.coordinates.count, 4)
        let coordinate = step.shape!.coordinates.first!
        XCTAssertEqual(round(coordinate.latitude), 33)
        XCTAssertEqual(round(coordinate.longitude), -117)
    }

    @MainActor
    func testMatchWithNullTracepoints() throws {
        let expectation = expectation(description: "calculating directions should return results")
        let locations = [
            CLLocationCoordinate2D(latitude: 32.70949, longitude: -117.17747),
            CLLocationCoordinate2D(latitude: 32.712256, longitude: -117.17291),
            CLLocationCoordinate2D(latitude: 32.712444, longitude: -117.17292),
            CLLocationCoordinate2D(latitude: 32.71257, longitude: -117.172922),
            CLLocationCoordinate2D(latitude: 32.7126, longitude: -117.172985),
            CLLocationCoordinate2D(latitude: 32.712597, longitude: -117.173143),
            CLLocationCoordinate2D(latitude: 32.712546, longitude: -117.173345),
        ]

        stub(
            condition: isHost("api.mapbox.com")
                && isMethodGET()
                && pathStartsWith("/matching/v5/mapbox/driving")
        ) { _ in
            let path = Bundle.module.path(forResource: "null-tracepoint", ofType: "json")
            return HTTPStubsResponse(
                fileAtPath: path!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }

        var match: Match!
        var tracepoints: [Match.Tracepoint?]!
        let matchOptions = MatchOptions(coordinates: locations)
        matchOptions.includesSteps = true
        matchOptions.routeShapeResolution = .full

        let task = Directions(credentials: BogusCredentials).calculate(matchOptions) { result in
            guard case .success(let resp) = result else {
                XCTFail("Encountered unexpected error. \(result)")
                return
            }
            Task { @MainActor [m = resp.matches?.first, t = resp.tracepoints] in
                match = m
                tracepoints = t
                expectation.fulfill()
            }
        }
        XCTAssertNotNil(task)

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, .completed)
        }

        _ = try XCTUnwrap(match)
        _ = try XCTUnwrap(tracepoints)
        XCTAssertEqual(tracepoints.count, 7)
        XCTAssertEqual(tracepoints.first!, nil)

        // Encode and decode the match securely.
        // This may raise an Objective-C exception if an error is encountered which will fail the tests.

        let encoded = try! JSONEncoder().encode(match)
        let encodedString = String(data: encoded, encoding: .utf8)!

        let decoder = JSONDecoder()
        decoder.userInfo[.options] = matchOptions
        let unarchivedMatch = try decoder.decode(Match.self, from: encodedString.data(using: .utf8)!)

        XCTAssertEqual(match.confidence, unarchivedMatch.confidence)
    }
#endif

    func testCoding() {
        // https://api.mapbox.com/matching/v5/mapbox/driving/-84.51200,39.09740;-84.51118,39.09638;-84.51021,39.09687?geometries=polyline&overview=false&tidy=false&access_token=…
        let matchJSON: [String: Any?] = [
            "confidence": 0.00007401405321383336,
            "legs": [
                [
                    "summary": "",
                    "weight": 46.7,
                    "duration": 34.7,
                    "steps": [],
                    "distance": 169,
                ],
                [
                    "summary": "",
                    "weight": 31,
                    "duration": 25.6,
                    "steps": [],
                    "distance": 128.1,
                ],
            ],
            "weight_name": "routability",
            "weight": 77.7,
            "duration": 60.300000000000004,
            "distance": 297.1,
        ]
        let matchData = try! JSONSerialization.data(withJSONObject: matchJSON, options: [])

        let options = MatchOptions(coordinates: [
            LocationCoordinate2D(latitude: 39.09740, longitude: -84.51200),
            LocationCoordinate2D(latitude: 39.09638, longitude: -84.51118),
            LocationCoordinate2D(latitude: 39.09687, longitude: -84.51021),
        ])
        options.routeShapeResolution = .none

        let decoder = JSONDecoder()
        var match: Match?
        XCTAssertThrowsError(match = try decoder.decode(Match.self, from: matchData))
        decoder.userInfo[.options] = options
        XCTAssertNoThrow(match = try decoder.decode(Match.self, from: matchData))
        XCTAssertNotNil(match)
    }
}
