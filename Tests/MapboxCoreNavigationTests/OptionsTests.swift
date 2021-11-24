import XCTest
import CoreLocation
import MapboxDirections
import TestHelper
@testable import MapboxCoreNavigation

class OptionsTests: TestCase {
    let coordinates = [CLLocationCoordinate2D(latitude: 0, longitude: 1), CLLocationCoordinate2D(latitude: 2, longitude: 3)]
    
    func testNavigationRouteOptions() {
        let options = NavigationRouteOptions(coordinates: coordinates)
        navigationPrerequisitesAssertions(options: options)
    }
    
    func testNavigationMatchOptions() {
        let options = NavigationMatchOptions(coordinates: coordinates)
        navigationPrerequisitesAssertions(options: options)
    }
    
    func navigationPrerequisitesAssertions(options: DirectionsOptions) {
        XCTAssertEqual(options.profileIdentifier, .automobileAvoidingTraffic)
        XCTAssertEqual(options.routeShapeResolution, .full)
        XCTAssertEqual(options.shapeFormat, .polyline6)
        XCTAssertEqual(options.attributeOptions, [.numericCongestionLevel, .expectedTravelTime, .maximumSpeedLimit])
        XCTAssertTrue(options.includesVisualInstructions)
        XCTAssertTrue(options.includesSpokenInstructions)
    }
    
    func testDefaultAttributeOptions() {
        XCTAssertEqual(NavigationRouteOptions(coordinates: coordinates).attributeOptions,
                       [.numericCongestionLevel, .expectedTravelTime, .maximumSpeedLimit])
        XCTAssertEqual(NavigationRouteOptions(coordinates: coordinates, profileIdentifier: .automobile).attributeOptions,
                       [.numericCongestionLevel, .expectedTravelTime, .maximumSpeedLimit])
        XCTAssertEqual(NavigationRouteOptions(coordinates: coordinates, profileIdentifier: .automobileAvoidingTraffic).attributeOptions,
                       [.numericCongestionLevel, .expectedTravelTime, .maximumSpeedLimit])
        // https://github.com/mapbox/mapbox-navigation-ios/issues/3495
        XCTAssertEqual(NavigationRouteOptions(coordinates: coordinates, profileIdentifier: .cycling).attributeOptions,
                       [.congestionLevel, .expectedTravelTime, .maximumSpeedLimit])
        XCTAssertEqual(NavigationRouteOptions(coordinates: coordinates, profileIdentifier: .walking).attributeOptions,
                       [.numericCongestionLevel, .expectedTravelTime, .maximumSpeedLimit])
        XCTAssertEqual(NavigationRouteOptions(coordinates: coordinates, profileIdentifier: .init(rawValue: "mapbox/unicycling")).attributeOptions,
                       [.numericCongestionLevel, .expectedTravelTime, .maximumSpeedLimit])
    }
}
