import XCTest
import CoreLocation
import MapboxDirections
@testable import MapboxCoreNavigation

class OptionsTests: XCTestCase {
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
        XCTAssertEqual(options.attributeOptions, [.congestionLevel, .expectedTravelTime, .maximumSpeedLimit])
        XCTAssertTrue(options.includesVisualInstructions)
        XCTAssertTrue(options.includesSpokenInstructions)
    }
}
