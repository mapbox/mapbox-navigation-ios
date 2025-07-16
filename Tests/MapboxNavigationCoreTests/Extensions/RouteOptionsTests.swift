import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
import XCTest

/// A hypothetical set of options optimized for golf carts.
/// This class uses options that may or may not be supported by the actual Mapbox Directions API.
final class GolfCartRouteOptions: NavigationRouteOptions, @unchecked Sendable {
    enum CodingKeys: String, CodingKey {
        case custom = "custom_key"
    }

    var custom: String = "custom_value"

    override var urlQueryItems: [URLQueryItem] {
        return super.urlQueryItems + [
            URLQueryItem(name: CodingKeys.custom.rawValue, value: custom),
        ]
    }

    required init(
        waypoints: [Waypoint],
        profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic,
        queryItems: [URLQueryItem]? = nil
    ) {
        super.init(waypoints: waypoints, profileIdentifier: profileIdentifier, queryItems: queryItems)
    }

    required init(from decoder: any Decoder) throws {
        try super.init(from: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.custom = try container.decode(String.self, forKey: .custom)
    }

    override func encode(to encoder: any Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(custom, forKey: .custom)
    }
}

class RouteOptionsTests: XCTestCase {
    var options: GolfCartRouteOptions!

    override func setUp() {
        super.setUp()

        let coordinates: [CLLocationCoordinate2D] = [
            .init(latitude: 0, longitude: 0),
            .init(latitude: 1, longitude: 1),
        ]
        options = GolfCartRouteOptions(coordinates: coordinates, profileIdentifier: .automobile)
    }

    func testCopying() {
        var copy: GolfCartRouteOptions?
        XCTAssertNoThrow(copy = try options.copy())
        XCTAssertNotNil(copy)
        XCTAssertTrue(copy?.urlQueryItems.contains(URLQueryItem(name: "custom_key", value: "custom_value")) ?? false)
    }

    func testEncoding() throws {
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(options)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GolfCartRouteOptions.self, from: encodedData)

        XCTAssertEqual(decoded.custom, "custom_value")
        XCTAssertTrue(decoded.urlQueryItems.contains(URLQueryItem(name: "custom_key", value: "custom_value")))
    }
}
