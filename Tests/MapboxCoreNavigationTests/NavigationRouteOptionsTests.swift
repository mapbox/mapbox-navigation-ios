import XCTest
import CoreLocation
import MapboxDirections
import TestHelper
@testable import MapboxCoreNavigation

final class NavigationRouteOptionsTests: TestCase {
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

    func navigationPrerequisitesAssertions(options: DirectionsOptions) {
        XCTAssertEqual(options.profileIdentifier, .automobileAvoidingTraffic)
        XCTAssertEqual(options.routeShapeResolution, .full)
        XCTAssertEqual(options.shapeFormat, .polyline6)
        XCTAssertEqual(options.attributeOptions, [.numericCongestionLevel, .expectedTravelTime, .maximumSpeedLimit])
        XCTAssertTrue(options.includesVisualInstructions)
        XCTAssertTrue(options.includesSpokenInstructions)
        XCTAssertTrue(options.includesSteps)
        XCTAssertEqual(options.locale, Locale.nationalizedCurrent)
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

    func testSetDistanceMeasurementSystem() {
        let queryItems1: [URLQueryItem] = [
            .init(name: "voice_units", value: "metric"),
            .init(name: "language", value: "ja_JP"),
        ]
        let options1 = NavigationRouteOptions(waypoints: waypoints, queryItems: queryItems1)
        XCTAssertEqual(options1.distanceMeasurementSystem, .metric)

        let queryItems2: [URLQueryItem] = [
            .init(name: "voice_units", value: "imperial"),
            .init(name: "language", value: "ja_JP"),
        ]
        let options2 = NavigationRouteOptions(waypoints: waypoints, queryItems: queryItems2)
        XCTAssertEqual(options2.distanceMeasurementSystem, .imperial)
    }
}
