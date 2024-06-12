import Foundation
@testable import MapboxDirections
import Turf
import XCTest

class ForeignMemberContainerTests: XCTestCase {
    func testRouteRefreshForeignMembersCoding() {
        guard let fixtureURL = Bundle.module.url(
            forResource: "RouteRefreshResponseWithForeignMembers",
            withExtension: "json"
        ) else {
            XCTFail()
            return
        }
        guard let fixtureData = try? Data(contentsOf: fixtureURL, options: .mappedIfSafe) else {
            XCTFail()
            return
        }

        var fixtureJSON: [String: Any?]?
        XCTAssertNoThrow(
            fixtureJSON = try JSONSerialization
                .jsonObject(with: fixtureData, options: []) as? [String: Any?]
        )

        let decoder = JSONDecoder()
        decoder.userInfo[.credentials] = BogusCredentials
        decoder.userInfo[.responseIdentifier] = "bogusId"
        decoder.userInfo[.routeIndex] = 0
        decoder.userInfo[.startLegIndex] = 0
        decoder.userInfo[.includesForeignMembers] = true

        var response: RouteRefreshResponse?
        XCTAssertNoThrow(response = try decoder.decode(RouteRefreshResponse.self, from: fixtureData))

        let encoder = JSONEncoder()
        encoder.userInfo[.includesForeignMembers] = true
        var encodedResponse: Data?
        var encodedRouteRefreshJSON: [String: Any?]?

        XCTAssertNoThrow(encodedResponse = try encoder.encode(response))
        XCTAssertNoThrow(encodedRouteRefreshJSON = try JSONSerialization.jsonObject(
            with: encodedResponse!,
            options: []
        ) as? [String: Any?])
        XCTAssertNotNil(encodedRouteRefreshJSON)

        // Remove default keys not found in the original API response.
        encodedRouteRefreshJSON?.removeValue(forKey: "uuid")

        XCTAssertTrue(JSONSerialization.objectsAreEqual(fixtureJSON, encodedRouteRefreshJSON, approximate: true))
    }

    func testRouteResponseForeignMembersCoding() {
        guard let fixtureURL = Bundle.module.url(
            forResource: "RouteResponseWithForeignMembers",
            withExtension: "json"
        ) else {
            XCTFail()
            return
        }
        guard let fixtureData = try? Data(contentsOf: fixtureURL, options: .mappedIfSafe) else {
            XCTFail()
            return
        }

        var fixtureJSON: [String: Any?]?
        XCTAssertNoThrow(
            fixtureJSON = try JSONSerialization
                .jsonObject(with: fixtureData, options: []) as? [String: Any?]
        )

        let options = RouteOptions(coordinates: [
            .init(
                latitude: 0,
                longitude: 0
            ),
            .init(
                latitude: 1,
                longitude: 1
            ),
        ])
        options.shapeFormat = .geoJSON
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = options
        decoder.userInfo[.credentials] = BogusCredentials
        decoder.userInfo[.includesForeignMembers] = true
        var response: RouteResponse?
        XCTAssertNoThrow(response = try decoder.decode(RouteResponse.self, from: fixtureData))

        let encoder = JSONEncoder()
        encoder.userInfo[.options] = options
        encoder.userInfo[.credentials] = BogusCredentials
        encoder.userInfo[.includesForeignMembers] = true

        var encodedResponse: Data?
        var encodedRouteResponseJSON: [String: Any?]?

        XCTAssertNoThrow(encodedResponse = try encoder.encode(response))
        XCTAssertNoThrow(encodedRouteResponseJSON = try JSONSerialization.jsonObject(
            with: encodedResponse!,
            options: []
        ) as? [String: Any?])
        XCTAssertNotNil(encodedRouteResponseJSON)

        // Remove default keys not found in the original API response.
        if var encodedRoutesJSON = encodedRouteResponseJSON?["routes"] as? [[String: Any?]] {
            if var encodedLegJSON = encodedRoutesJSON[0]["legs"] as? [[String: Any?]] {
                encodedLegJSON[0].removeValue(forKey: "source")
                encodedLegJSON[0].removeValue(forKey: "destination")
                encodedLegJSON[0].removeValue(forKey: "profileIdentifier")

                encodedRoutesJSON[0]["legs"] = encodedLegJSON
                encodedRouteResponseJSON?["routes"] = encodedRoutesJSON
            }
        }
        if var encodedWaypointsJSON = encodedRouteResponseJSON?["waypoints"] as? [[String: Any?]] {
            encodedWaypointsJSON[0].removeValue(forKey: "separatesLegs")
            encodedWaypointsJSON[0].removeValue(forKey: "allowsArrivingOnOppositeSide")
            encodedWaypointsJSON[1].removeValue(forKey: "separatesLegs")
            encodedWaypointsJSON[1].removeValue(forKey: "allowsArrivingOnOppositeSide")

            encodedRouteResponseJSON?["waypoints"] = encodedWaypointsJSON
        }

        XCTAssertTrue(JSONSerialization.objectsAreEqual(fixtureJSON, encodedRouteResponseJSON, approximate: true))
    }
}
