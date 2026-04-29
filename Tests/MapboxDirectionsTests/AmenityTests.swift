import MapboxDirections
import Turf
import XCTest

final class AmenityTests: XCTestCase {
    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testAmenitiesDecoding() {
        let routeData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.module.path(
            forResource: "amenities",
            ofType: "json"
        )!))
        let routeOptions = RouteOptions(coordinates: [
            LocationCoordinate2D(latitude: 37.78, longitude: -122.42),
            LocationCoordinate2D(latitude: 38.91, longitude: -77.03),
        ])

        let decoder = JSONDecoder()
        decoder.userInfo[.options] = routeOptions
        decoder.userInfo[.credentials] = Credentials(
            accessToken: "access_token",
            host: URL(string: "http://test_host.com")
        )

        let routeResponse = try! decoder.decode(RouteResponse.self, from: routeData)
        guard let leg = routeResponse.routes?.first?.legs.first else {
            XCTFail("Route leg should be valid.")
            return
        }

        let expectedStepsCount = 2
        if leg.steps.count != expectedStepsCount {
            XCTFail("Route should have two steps.")
            return
        }

        guard let intersections = leg.steps.first?.intersections else {
            XCTFail("Intersections should be valid.")
            return
        }

        let expectedIntersectionsCount = 6
        if intersections.count != expectedIntersectionsCount {
            XCTFail("Number of intersections should be valid.")
            return
        }

        guard let restStop = intersections[4].restStop else {
            XCTFail("Rest stop should be valid.")
            return
        }

        guard let amenities = restStop.amenities else {
            XCTFail("Amenities should be present.")
            return
        }

        XCTAssertEqual(amenities.count, 7)

        XCTAssertEqual(amenities[1].type, .coffee)
        XCTAssertNil(amenities[1].name)
        XCTAssertNil(amenities[1].brand)

        XCTAssertEqual(amenities[6].type, .telephone)
        XCTAssertEqual(amenities[6].name, "test_name")
        XCTAssertEqual(amenities[6].brand, "test_brand")
    }

    func testAmenityEncoding() {
        let coffeeAmenity = Amenity(
            type: .coffee,
            name: "amenity_name",
            brand: "amenity_brand"
        )
        XCTAssertEqual(
            encode(coffeeAmenity),
            "{\"brand\":\"amenity_brand\",\"name\":\"amenity_name\",\"type\":\"coffee\"}"
        )

        let undefinedAmenity = Amenity(type: .undefined)
        XCTAssertEqual(encode(undefinedAmenity), "{\"type\":\"undefined\"}")
    }

    func testAmenityEquality() {
        var firstEmenity = Amenity(type: .coffee)
        var secondEmenity = Amenity(type: .coffee)
        XCTAssertEqual(firstEmenity, secondEmenity)

        firstEmenity = Amenity(
            type: .coffee,
            name: "name",
            brand: "brand"
        )
        secondEmenity = Amenity(
            type: .coffee,
            name: "name",
            brand: "brand"
        )
        XCTAssertEqual(firstEmenity, secondEmenity)

        firstEmenity = Amenity(
            type: .undefined,
            name: "undefined_name",
            brand: "brand"
        )
        secondEmenity = Amenity(
            type: .babyCare,
            name: "name",
            brand: "brand"
        )
        XCTAssertNotEqual(firstEmenity, secondEmenity)
    }

    func encode(_ amenity: Amenity) -> String? {
        var jsonData: Data?
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        XCTAssertNoThrow(jsonData = try encoder.encode(amenity))
        XCTAssertNotNil(jsonData)

        guard let jsonData else {
            XCTFail("Encoded amenity should be valid.")
            return nil
        }

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            XCTFail("Encoded amenity should be valid.")
            return nil
        }

        return jsonString
    }
}
