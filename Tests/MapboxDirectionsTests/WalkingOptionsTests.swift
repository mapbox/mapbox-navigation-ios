@testable import MapboxDirections
import Turf
import XCTest

class WalkingOptionsTests: XCTestCase {
    func testURLQueryParams() {
        let waypoints = [
            Waypoint(coordinate: LocationCoordinate2D(latitude: 0, longitude: 1)),
            Waypoint(coordinate: LocationCoordinate2D(latitude: 2, longitude: 3)),
        ]

        let options = RouteOptions(waypoints: waypoints, profileIdentifier: ProfileIdentifier.walking)
        var queryItems = options.urlQueryItems
        XCTAssertNil(queryItems.first { $0.name == "alley_bias" }?.value)
        XCTAssertNil(queryItems.first { $0.name == "walkway_bias" }?.value)
        XCTAssertNil(queryItems.first { $0.name == "walking_speed" }?.value)

        options.alleyPriority = DirectionsPriority(rawValue: 0.4)
        options.walkwayPriority = DirectionsPriority(rawValue: 0.5)
        options.speed = 5.2

        queryItems = options.urlQueryItems

        XCTAssertEqual(queryItems.first { $0.name == "alley_bias" }?.value, "0.4")
        XCTAssertEqual(queryItems.first { $0.name == "walkway_bias" }?.value, "0.5")
        XCTAssertEqual(queryItems.first { $0.name == "walking_speed" }?.value, "5.2")
    }
}
