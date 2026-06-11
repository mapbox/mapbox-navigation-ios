@testable import MapboxDirections
import Turf
import XCTest

final class LocationCoordinate2DCodableTests: XCTestCase {
    func testEncodingUsesLongitudeLatitudeOrder() throws {
        let coordinate = LocationCoordinate2DCodable(
            Turf.LocationCoordinate2D(latitude: 37.5, longitude: -122.3)
        )
        let data = try JSONEncoder().encode(coordinate)
        let array = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [Double])
        XCTAssertEqual(array, [-122.3, 37.5])
    }

    func testDecodingReadsLongitudeLatitudeOrder() throws {
        let json = "[-122.3, 37.5]".data(using: .utf8)!
        let coordinate = try JSONDecoder().decode(LocationCoordinate2DCodable.self, from: json)
        XCTAssertEqual(coordinate.longitude, -122.3)
        XCTAssertEqual(coordinate.latitude, 37.5)
    }

    func testDecodedPropertyReturnsCorrectCoordinate() throws {
        let json = "[-122.3, 37.5]".data(using: .utf8)!
        let coordinate = try JSONDecoder().decode(LocationCoordinate2DCodable.self, from: json)
        XCTAssertEqual(coordinate.decoded.latitude, 37.5)
        XCTAssertEqual(coordinate.decoded.longitude, -122.3)
    }

    func testRoundTrip() throws {
        let original = LocationCoordinate2DCodable(
            Turf.LocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LocationCoordinate2DCodable.self, from: data)
        XCTAssertEqual(decoded.latitude, original.latitude)
        XCTAssertEqual(decoded.longitude, original.longitude)
    }
}
