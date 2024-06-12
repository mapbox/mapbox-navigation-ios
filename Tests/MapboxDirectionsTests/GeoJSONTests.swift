@testable import MapboxDirections
import Turf
import XCTest

class GeoJSONTests: XCTestCase {
    func testInitialization() {
        XCTAssertThrowsError(try LineString(encodedPolyline: ">==========>", precision: 1e6))

        var lineString: LineString? = nil
        XCTAssertNoThrow(lineString = try LineString(encodedPolyline: "afvnFdrebO@o@", precision: 1e5))
        XCTAssertNotNil(lineString)
        XCTAssertEqual(lineString?.coordinates.count, 2)
        XCTAssertEqual(lineString?.coordinates.first?.latitude ?? 0.0, 39.27665, accuracy: 1e-5)
        XCTAssertEqual(lineString?.coordinates.first?.longitude ?? 0.0, -84.411389, accuracy: 1e-5)
        XCTAssertEqual(lineString?.coordinates.last?.latitude ?? 0.0, 39.276635, accuracy: 1e-5)
        XCTAssertEqual(lineString?.coordinates.last?.longitude ?? 0.0, -84.411148, accuracy: 1e-5)
    }

    func testZeroLengthWorkaround() {
        var lineString: LineString? = nil

        // Correctly encoded zero-length LineString
        // https://github.com/mapbox/mapbox-navigation-ios/issues/2611
        XCTAssertNoThrow(lineString = try LineString(encodedPolyline: "s{byuAnigzhF??", precision: 1e6))
        XCTAssertNotNil(lineString)
        XCTAssertEqual(lineString?.coordinates.count, 2)
        XCTAssertEqual(lineString?.coordinates.first, lineString?.coordinates.last)
        XCTAssertEqual(lineString?.polylineEncodedString(precision: 1e6), "s{byuAnigzhF??")

        // Incorrectly encoded zero-length LineString
        XCTAssertNoThrow(lineString = try LineString(encodedPolyline: "s{byuArigzhF", precision: 1e6))
        XCTAssertNotNil(lineString)
        XCTAssertEqual(lineString?.coordinates.count, 2)
        XCTAssertEqual(lineString?.coordinates.first, lineString?.coordinates.last)
        XCTAssertEqual(lineString?.polylineEncodedString(precision: 1e6), "s{byuArigzhF??")
    }

    func testLineStringCoding() throws {
        let coordinates: [LocationCoordinate2D] = [
            .init(latitude: 0, longitude: 0),
            .init(latitude: 1, longitude: 1),
            .init(latitude: -1, longitude: -1),
        ]
        let options = RouteOptions(coordinates: coordinates)
        options.shapeFormat = .geoJSON

        let json: [String: Any?] = [
            "type": "LineString",
            "coordinates": [[0, 0], [1, 1], [-1, -1]],
        ]
        let data = try JSONSerialization.data(withJSONObject: json, options: [])

        let decoder = JSONDecoder()
        decoder.userInfo[.options] = options
        let polyLineString = try decoder.decode(PolyLineString.self, from: data)
        guard case .lineString = polyLineString else {
            XCTFail("Should decode polyline/linestring as linestring.")
            return
        }

        let encoder = JSONEncoder()
        encoder.userInfo[.options] = options
        let reencodedData = try encoder.encode(polyLineString)
        let reencodedJSON = try JSONSerialization.jsonObject(with: reencodedData, options: [])
        XCTAssertEqual(json as NSDictionary, reencodedJSON as? NSDictionary)
    }
}
