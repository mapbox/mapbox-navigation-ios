import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
import XCTest

final class NavigationRouteOptionsTests: XCTestCase {
    let coordinates = [
        CLLocationCoordinate2D(latitude: 0, longitude: 1),
        CLLocationCoordinate2D(latitude: 2, longitude: 3),
    ]

    var waypoints: [Waypoint] {
        coordinates.map { Waypoint(coordinate: $0) }
    }

    func testNavigationRouteOptions() {
        let options = NavigationRouteOptions(coordinates: coordinates)
        navigationPrerequisitesAssertions(options: options)
    }

    func navigationPrerequisitesAssertions(options: NavigationRouteOptions) {
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
            NavigationRouteOptions(coordinates: coordinates).attributeOptions,
            [.numericCongestionLevel, .expectedTravelTime, .maximumSpeedLimit]
        )
        XCTAssertEqual(
            NavigationRouteOptions(coordinates: coordinates, profileIdentifier: .automobile).attributeOptions,
            [.expectedTravelTime, .maximumSpeedLimit]
        )
        XCTAssertEqual(
            NavigationRouteOptions(coordinates: coordinates, profileIdentifier: .automobileAvoidingTraffic)
                .attributeOptions,
            [.numericCongestionLevel, .expectedTravelTime, .maximumSpeedLimit]
        )
        // https://github.com/mapbox/mapbox-navigation-ios/issues/3495
        XCTAssertEqual(
            NavigationRouteOptions(coordinates: coordinates, profileIdentifier: .cycling).attributeOptions,
            [.expectedTravelTime, .maximumSpeedLimit]
        )
        XCTAssertEqual(
            NavigationRouteOptions(coordinates: coordinates, profileIdentifier: .walking).attributeOptions,
            [.expectedTravelTime, .maximumSpeedLimit]
        )
        XCTAssertEqual(
            NavigationRouteOptions(coordinates: coordinates, profileIdentifier: .init(rawValue: "mapbox/unicycling"))
                .attributeOptions,
            [.expectedTravelTime, .maximumSpeedLimit]
        )
    }

    @available(*, deprecated)
    func testSetDistanceMeasurementSystem() {
        let locale = Locale(identifier: "en_US")
        let waypoints = coordinates.map { Waypoint(coordinate: $0) }

        let options1 = NavigationRouteOptions(
            waypoints: waypoints,
            locale: locale,
            distanceUnit: .meter
        )
        XCTAssertEqual(options1.distanceMeasurementSystem, .metric)

        let options2 = NavigationRouteOptions(
            waypoints: waypoints,
            locale: locale,
            distanceUnit: .mile
        )
        XCTAssertEqual(options2.distanceMeasurementSystem, .imperial)

        let options3 = NavigationRouteOptions(
            waypoints: waypoints,
            locale: locale,
            distanceUnit: .yard
        )
        XCTAssertEqual(options3.distanceMeasurementSystem, .imperial)
    }

    func testSetUnitMeasurementSystem() {
        let locale = Locale(identifier: "en_US")
        let waypoints = coordinates.map { Waypoint(coordinate: $0) }

        let options1 = NavigationRouteOptions(
            waypoints: waypoints,
            locale: locale,
            distanceUnit: .meter
        )
        XCTAssertEqual(options1.unitMeasurementSystem, .metric)

        let options2 = NavigationRouteOptions(
            waypoints: waypoints,
            locale: locale,
            distanceUnit: .mile
        )
        XCTAssertEqual(options2.unitMeasurementSystem, .imperial)

        let options3 = NavigationRouteOptions(
            waypoints: waypoints,
            locale: locale,
            distanceUnit: .yard
        )
        XCTAssertEqual(options3.unitMeasurementSystem, .britishImperial)

        let options4 = NavigationRouteOptions(
            waypoints: waypoints,
            locale: locale,
            distanceUnit: .foot
        )
        XCTAssertEqual(options4.unitMeasurementSystem, .imperial)
    }

    func testSetShapeFormat() {
        let queryItems: [URLQueryItem] = [.init(name: "geometries", value: "geojson")]
        let options = NavigationRouteOptions(waypoints: waypoints, queryItems: queryItems)
        XCTAssertEqual(options.shapeFormat, .geoJSON)
    }

    func testSetIncludesSteps() {
        let queryItems: [URLQueryItem] = [.init(name: "steps", value: "false")]
        let options = NavigationRouteOptions(waypoints: waypoints, queryItems: queryItems)
        XCTAssertFalse(options.includesSteps)
    }

    func testSetIncludesSpokenInstructions() {
        let queryItems: [URLQueryItem] = [.init(name: "voice_instructions", value: "false")]
        let options = NavigationRouteOptions(waypoints: waypoints, queryItems: queryItems)
        XCTAssertFalse(options.includesSpokenInstructions)
    }

    func testSetIncludesVisualInstructions() {
        let queryItems: [URLQueryItem] = [.init(name: "banner_instructions", value: "false")]
        let options = NavigationRouteOptions(waypoints: waypoints, queryItems: queryItems)
        XCTAssertFalse(options.includesVisualInstructions)
    }

    func testSetRouteShapeResolution() {
        let queryItems: [URLQueryItem] = [.init(name: "overview", value: "low")]
        let options = NavigationRouteOptions(waypoints: waypoints, queryItems: queryItems)
        XCTAssertEqual(options.routeShapeResolution, .low)
    }

    func testSetLocale() {
        let queryItems: [URLQueryItem] = [.init(name: "language", value: "ja_JP")]
        let options = NavigationRouteOptions(waypoints: waypoints, queryItems: queryItems)
        XCTAssertEqual(options.locale, .init(identifier: "ja_JP"))
    }

    func testSetUnitMeasurementSystemFromQueryItems() {
        let queryItems1: [URLQueryItem] = [
            .init(name: "voice_units", value: "metric"),
            .init(name: "language", value: "ja_JP"),
        ]
        let options1 = NavigationRouteOptions(waypoints: waypoints, queryItems: queryItems1)
        XCTAssertEqual(options1.unitMeasurementSystem, .metric)

        let queryItems2: [URLQueryItem] = [
            .init(name: "voice_units", value: "imperial"),
            .init(name: "language", value: "ja_JP"),
        ]
        let options2 = NavigationRouteOptions(waypoints: waypoints, queryItems: queryItems2)
        XCTAssertEqual(options2.unitMeasurementSystem, .imperial)

        let queryItems3: [URLQueryItem] = [
            .init(name: "voice_units", value: "british_imperial"),
            .init(name: "language", value: "ja_JP"),
        ]
        let options3 = NavigationRouteOptions(waypoints: waypoints, queryItems: queryItems3)
        XCTAssertEqual(options3.unitMeasurementSystem, .britishImperial)
    }
}
