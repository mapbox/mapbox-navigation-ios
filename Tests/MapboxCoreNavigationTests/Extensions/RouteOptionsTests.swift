import XCTest
import CoreLocation
import MapboxDirections
@testable import MapboxCoreNavigation

/**
 A hypothetical set of options optimized for golf carts.
 
 This class uses options that may or may not be supported by the actual Mapbox Directions API.
 */
class GolfCartRouteOptions: NavigationRouteOptions {
    override var urlQueryItems: [URLQueryItem] {
        let maximumSpeed = Measurement(value: 20, unit: UnitSpeed.milesPerHour) // maximum legal speed in Ohio
        let hourFromNow = Date().addingTimeInterval(60 * 60) // an hour from now
        let hourFromNowString = ISO8601DateFormatter.string(from: hourFromNow, timeZone: .current, formatOptions: .withInternetDateTime)
        return super.urlQueryItems + [
            URLQueryItem(name: "maxspeed", value: String(maximumSpeed.converted(to: .kilometersPerHour).value)),
            URLQueryItem(name: "depart_at", value: hourFromNowString),
            URLQueryItem(name: "passengers", value: "3"),
        ]
    }
}

class RouteOptionsTests: XCTestCase {
    func testCopying() {
        let coordinates: [CLLocationCoordinate2D] = [
            .init(latitude: 0, longitude: 0),
            .init(latitude: 1, longitude: 1),
        ]
        let options = GolfCartRouteOptions(coordinates: coordinates, profileIdentifier: .automobile)
        var copy: GolfCartRouteOptions?
        XCTAssertNoThrow(copy = try options.copy())
        XCTAssertNotNil(copy)
        XCTAssertTrue(copy?.urlQueryItems.contains(URLQueryItem(name: "passengers", value: "3")) ?? false)
    }
}
