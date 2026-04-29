import XCTest
#if !os(Linux)
import CoreLocation
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif
@testable import MapboxDirections

class RoutableMatchTest: XCTestCase {
    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    @MainActor
    func testRoutableMatch() throws {
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
            let path = Bundle.module.path(forResource: "match-polyline6", ofType: "json")
            return HTTPStubsResponse(
                fileAtPath: path!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }

        var waypoints: [Waypoint]!
        var route: Route!

        let matchOptions = MatchOptions(coordinates: locations)
        matchOptions.shapeFormat = .polyline6
        matchOptions.includesSteps = true
        matchOptions.routeShapeResolution = .full
        for index in 1..<(locations.count - 1) {
            matchOptions.waypoints[index].separatesLegs = false
        }

        let task = Directions(credentials: BogusCredentials).calculateRoutes(matching: matchOptions) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error: \(error)")
            case .success(let response):
                Task { @MainActor [r = response.routes?.first, w = response.waypoints] in
                    waypoints = w
                    route = r
                    expectation.fulfill()
                }
            }
        }
        XCTAssertNotNil(task)

        waitForExpectations(timeout: 20) { error in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, .completed)
        }
        _ = try XCTUnwrap(route)
        _ = try XCTUnwrap(waypoints)
        XCTAssertNotNil(route.shape)
        XCTAssertEqual(route.shape!.coordinates.count, 19)

        XCTAssertEqual(waypoints.first!.name, "North Harbor Drive")
        XCTAssertEqual(waypoints.last!.name, "West G Street")
        XCTAssertNotNil(waypoints.last!.coordinate)

        // confirming actual decoded values is important because the Directions API
        // uses an atypical precision level for polyline encoding
        XCTAssertEqual(round(route.shape!.coordinates.first!.latitude), 33)
        XCTAssertEqual(round(route.shape!.coordinates.first!.longitude), -117)
        XCTAssertEqual(route.legs.count, 6)

        let leg = route.legs.first!
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

        XCTAssertNotNil(step.shape)
        XCTAssertEqual(step.shape!.coordinates.count, 5)
        let coordinate = step.shape!.coordinates.first!
        XCTAssertEqual(round(coordinate.latitude), 33)
        XCTAssertEqual(round(coordinate.longitude), -117)
    }
}
#endif
