import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
import XCTest

final class NavigationMatchOptionsTests: XCTestCase {
    let coordinates = [
        CLLocationCoordinate2D(latitude: 0, longitude: 1),
        CLLocationCoordinate2D(latitude: 2, longitude: 3),
    ]

    var waypoints: [Waypoint] {
        coordinates.map { Waypoint(coordinate: $0) }
    }

    func testNavigationMatchOptions() {
        let options = NavigationMatchOptions(coordinates: coordinates)
        navigationPrerequisitesAssertions(options: options)
    }

    func navigationPrerequisitesAssertions(options: NavigationMatchOptions) {
        XCTAssertEqual(options.profileIdentifier, .automobileAvoidingTraffic)
        XCTAssertEqual(options.routeShapeResolution, .full)
        XCTAssertEqual(options.shapeFormat, .polyline6)
        XCTAssertEqual(options.attributeOptions, [.numericCongestionLevel, .expectedTravelTime, .maximumSpeedLimit])
        XCTAssertTrue(options.includesVisualInstructions)
        XCTAssertTrue(options.includesSpokenInstructions)
        XCTAssertTrue(options.includesSteps)
        XCTAssertEqual(options.locale, Locale.nationalizedCurrent)
        let unitMeasurementSystem: UnitMeasurementSystem = .init(options.distanceUnit)
        XCTAssertEqual(options.unitMeasurementSystem, unitMeasurementSystem)
    }

    func testDefaultAttributeOptions() {
        XCTAssertEqual(
            NavigationMatchOptions(coordinates: coordinates).attributeOptions,
            [.numericCongestionLevel, .expectedTravelTime, .maximumSpeedLimit]
        )
        XCTAssertEqual(
            NavigationMatchOptions(coordinates: coordinates, profileIdentifier: .automobile).attributeOptions,
            [.expectedTravelTime, .maximumSpeedLimit]
        )
        XCTAssertEqual(
            NavigationMatchOptions(coordinates: coordinates, profileIdentifier: .automobileAvoidingTraffic)
                .attributeOptions,
            [.numericCongestionLevel, .expectedTravelTime, .maximumSpeedLimit]
        )
        XCTAssertEqual(
            NavigationMatchOptions(coordinates: coordinates, profileIdentifier: .cycling).attributeOptions,
            [.expectedTravelTime]
        )
        XCTAssertEqual(
            NavigationMatchOptions(coordinates: coordinates, profileIdentifier: .walking).attributeOptions,
            [.expectedTravelTime]
        )
        XCTAssertEqual(
            NavigationMatchOptions(coordinates: coordinates, profileIdentifier: .init(rawValue: "mapbox/unicycling"))
                .attributeOptions,
            [.expectedTravelTime]
        )
    }

    @available(*, deprecated)
    func testSetDistanceMeasurementSystem() {
        let waypoints = coordinates.map { Waypoint(coordinate: $0) }

        let options1 = NavigationMatchOptions(waypoints: waypoints, distanceUnit: .meter)
        XCTAssertEqual(options1.distanceMeasurementSystem, .metric)

        let options2 = NavigationMatchOptions(waypoints: waypoints, distanceUnit: .mile)
        XCTAssertEqual(options2.distanceMeasurementSystem, .imperial)

        let options3 = NavigationMatchOptions(waypoints: waypoints, distanceUnit: .yard)
        XCTAssertEqual(options3.distanceMeasurementSystem, .imperial)
    }

    func testSetUnitMeasurementSystem() {
        let waypoints = coordinates.map { Waypoint(coordinate: $0) }

        let options1 = NavigationMatchOptions(waypoints: waypoints, distanceUnit: .meter)
        XCTAssertEqual(options1.unitMeasurementSystem, .metric)

        let options2 = NavigationMatchOptions(waypoints: waypoints, distanceUnit: .mile)
        XCTAssertEqual(options2.unitMeasurementSystem, .imperial)

        let options3 = NavigationMatchOptions(waypoints: waypoints, distanceUnit: .yard)
        XCTAssertEqual(options3.unitMeasurementSystem, .britishImperial)

        let options4 = NavigationMatchOptions(waypoints: waypoints, distanceUnit: .foot)
        XCTAssertEqual(options4.unitMeasurementSystem, .imperial)
    }

    func testSetShapeFormat() {
        let queryItems: [URLQueryItem] = [.init(name: "geometries", value: "geojson")]
        let options = NavigationMatchOptions(waypoints: waypoints, queryItems: queryItems)
        XCTAssertEqual(options.shapeFormat, .geoJSON)
    }

    func testSetIncludesSteps() {
        let queryItems: [URLQueryItem] = [.init(name: "steps", value: "false")]
        let options = NavigationMatchOptions(waypoints: waypoints, queryItems: queryItems)
        XCTAssertFalse(options.includesSteps)
    }

    func testSetIncludesSpokenInstructions() {
        let queryItems: [URLQueryItem] = [.init(name: "voice_instructions", value: "false")]
        let options = NavigationMatchOptions(waypoints: waypoints, queryItems: queryItems)
        XCTAssertFalse(options.includesSpokenInstructions)
    }

    func testSetIncludesVisualInstructions() {
        let queryItems: [URLQueryItem] = [.init(name: "banner_instructions", value: "false")]
        let options = NavigationMatchOptions(waypoints: waypoints, queryItems: queryItems)
        XCTAssertFalse(options.includesVisualInstructions)
    }

    func testSetRouteShapeResolution() {
        let queryItems: [URLQueryItem] = [.init(name: "overview", value: "low")]
        let options = NavigationMatchOptions(waypoints: waypoints, queryItems: queryItems)
        XCTAssertEqual(options.routeShapeResolution, .low)
    }

    func testSetLocale() {
        let queryItems: [URLQueryItem] = [.init(name: "language", value: "ja_JP")]
        let options = NavigationMatchOptions(waypoints: waypoints, queryItems: queryItems)
        XCTAssertEqual(options.locale, .init(identifier: "ja_JP"))
    }

    func testSetUnitMeasurementSystemFromQueryItems() {
        let queryItems1: [URLQueryItem] = [
            .init(name: "voice_units", value: "metric"),
            .init(name: "language", value: "ja_JP"),
        ]
        let options1 = NavigationMatchOptions(waypoints: waypoints, queryItems: queryItems1)
        XCTAssertEqual(options1.unitMeasurementSystem, .metric)

        let queryItems2: [URLQueryItem] = [
            .init(name: "voice_units", value: "imperial"),
            .init(name: "language", value: "ja_JP"),
        ]
        let options2 = NavigationMatchOptions(waypoints: waypoints, queryItems: queryItems2)
        XCTAssertEqual(options2.unitMeasurementSystem, .imperial)

        let queryItems3: [URLQueryItem] = [
            .init(name: "voice_units", value: "british_imperial"),
            .init(name: "language", value: "ja_JP"),
        ]
        let options3 = NavigationMatchOptions(waypoints: waypoints, queryItems: queryItems3)
        XCTAssertEqual(options3.unitMeasurementSystem, .britishImperial)
    }
}
