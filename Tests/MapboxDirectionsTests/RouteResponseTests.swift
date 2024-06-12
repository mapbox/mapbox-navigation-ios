@testable import MapboxDirections
import Turf
import XCTest

class RouteResponseTests: XCTestCase {
    func testRouteResponseEncodingAndDecoding() {
        let originCoordinate = LocationCoordinate2D(latitude: 39.15031, longitude: -84.47182)
        var originWaypoint = Waypoint(coordinate: originCoordinate, name: "Test origin waypoint")
        originWaypoint.targetCoordinate = originCoordinate
        originWaypoint.coordinateAccuracy = 1.0
        originWaypoint.heading = 120.0
        originWaypoint.headingAccuracy = 1.0
        originWaypoint.separatesLegs = false
        originWaypoint.allowsArrivingOnOppositeSide = false

        let destinationCoordinate = LocationCoordinate2D(latitude: 39.15031, longitude: -84.47865)
        let destinationWaypoint = Waypoint(coordinate: destinationCoordinate, name: "Test destination waypoint")

        let waypoints = [originWaypoint, destinationWaypoint]
        let routeOptions = RouteOptions(waypoints: waypoints)
        let responseOptions = ResponseOptions.route(routeOptions)

        let routeResponse = RouteResponse(
            httpResponse: nil,
            waypoints: waypoints,
            options: responseOptions,
            credentials: BogusCredentials,
            refreshTTL: 123.4
        )

        do {
            let encodedRouteResponse = try JSONEncoder().encode(routeResponse)

            let decoder = JSONDecoder()
            decoder.userInfo[.options] = routeOptions
            decoder.userInfo[.credentials] = BogusCredentials

            let decodedRouteResponse = try decoder.decode(RouteResponse.self, from: encodedRouteResponse)

            guard let waypoint = decodedRouteResponse.waypoints?.first else {
                XCTFail("Decoded route response should contain one waypoint.")
                return
            }

            let decodedCoordinate = waypoint.coordinate
            let decodedName = waypoint.name
            let decodedTargetCoordinate = waypoint.targetCoordinate
            let decodedCoordinateAccuracy = waypoint.coordinateAccuracy
            let decodedHeading = waypoint.heading
            let decodedHeadingAccuracy = waypoint.headingAccuracy
            let decodedSeparatesLegs = waypoint.separatesLegs
            let decodedAllowsArrivingOnOppositeSide = waypoint.allowsArrivingOnOppositeSide

            XCTAssertEqual(
                originWaypoint.coordinate,
                decodedCoordinate,
                "Original and decoded coordinates should be equal."
            )
            XCTAssertEqual(originWaypoint.name, decodedName, "Original and decoded names should be equal.")
            XCTAssertEqual(
                originWaypoint.targetCoordinate,
                decodedTargetCoordinate,
                "Original and decoded targetCoordinates should be equal."
            )
            XCTAssertEqual(
                originWaypoint.coordinateAccuracy,
                decodedCoordinateAccuracy,
                "Original and decoded coordinateAccuracies should be equal."
            )
            XCTAssertEqual(originWaypoint.heading, decodedHeading, "Original and decoded headings should be equal.")
            XCTAssertEqual(
                originWaypoint.headingAccuracy,
                decodedHeadingAccuracy,
                "Original and decoded headingAccuracies should be equal."
            )
            XCTAssertEqual(
                originWaypoint.separatesLegs,
                false,
                "originWaypoint should have separatesLegs set to false."
            )
            XCTAssertEqual(
                decodedSeparatesLegs,
                true,
                "First and last decoded waypoints should have separatesLegs value set to true."
            )
            XCTAssertEqual(
                originWaypoint.allowsArrivingOnOppositeSide,
                decodedAllowsArrivingOnOppositeSide,
                "Original and decoded allowsArrivingOnOppositeSides should be equal."
            )
            XCTAssertEqual(
                routeResponse.refreshTTL,
                decodedRouteResponse.refreshTTL,
                "Original and decoded refreshTTL should be equal."
            )
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    func testRoadClassesViolations() {
        guard let fixtureURL = Bundle.module.url(forResource: "tollAndFerryDirectionsRoute", withExtension: "json")
        else {
            XCTFail()
            return
        }
        guard let fixtureData = try? Data(contentsOf: fixtureURL, options: .mappedIfSafe) else {
            XCTFail()
            return
        }

        let options = RouteOptions(coordinates: [
            .init(
                latitude: 14.758522,
                longitude: 55.193541
            ),
            .init(
                latitude: 12.54072,
                longitude: 55.685213
            ),
        ])
        options.roadClassesToAvoid = [.ferry, .toll]
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = options
        decoder.userInfo[.credentials] = BogusCredentials
        var response: RouteResponse?
        XCTAssertNoThrow(response = try decoder.decode(RouteResponse.self, from: fixtureData))

        guard let unwrappedResponse = response else {
            XCTFail("Failed to decode route fixture.")
            return
        }

        let roadClassesViolations = unwrappedResponse.roadClassExclusionViolations

        XCTAssertNotNil(roadClassesViolations)
        XCTAssertEqual(roadClassesViolations?.count, 77, "Incorrect number of RoadClassViolations found")
        XCTAssertEqual(
            unwrappedResponse.exclusionViolations(routeIndex: 0, legIndex: 0, stepIndex: 9, intersectionIndex: 0).first!
                .roadClasses,
            .ferry
        )
        XCTAssertEqual(
            unwrappedResponse.exclusionViolations(routeIndex: 0, legIndex: 0, stepIndex: 24, intersectionIndex: 7)
                .first!.roadClasses,
            .toll
        )
    }
}
