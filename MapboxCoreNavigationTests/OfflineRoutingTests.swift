import XCTest
import MapboxDirections
@testable import MapboxCoreNavigation

class OfflineRoutingTests: XCTestCase {
    
    func testOfflineDirections() {
        let bundle = Bundle(for: OfflineRoutingTests.self)
        let tilesPath = URL(fileURLWithPath: bundle.bundlePath.appending("/routing/liechtenstein"))
        let translationsPath = URL(fileURLWithPath: bundle.bundlePath.appending("/translations"))
        
        let setupExpectation = expectation(description: "Set up offline routing")
        
        let directions = MapboxOfflineDirections(tilesPath: tilesPath, translationsPath: translationsPath, accessToken: "foo") { (numberOfTiles) in
            XCTAssertEqual(numberOfTiles, 5)
            setupExpectation.fulfill()
        }
        
        wait(for: [setupExpectation], timeout: 2)

        // Coordinates within Liechtenstein
        let coordinates = [CLLocationCoordinate2D(latitude: 47.1192, longitude: 9.5412),
                           CLLocationCoordinate2D(latitude: 47.1153, longitude: 9.5531)]

        let options = NavigationRouteOptions(coordinates: coordinates, profileIdentifier: .automobile)
        let calculateRouteExpectation = expectation(description: "Calculate route offline")
        var route: Route?
        
        directions.calculateOffline(options) { (waypoints, routes, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(waypoints)
            XCTAssertNotNil(routes)
            route = routes!.first!
            calculateRouteExpectation.fulfill()
        }

        wait(for: [calculateRouteExpectation], timeout: 2)
        
        XCTAssertNotNil(route)
        XCTAssertEqual(route!.coordinates!.count, 239)
    }
    
    func testOfflineDirectionsError() {
        let bundle = Bundle(for: OfflineRoutingTests.self)
        let tilesPath = URL(fileURLWithPath: bundle.bundlePath).appendingPathComponent("/routing/liechtenstein")
        let translationsPath = URL(fileURLWithPath: bundle.bundlePath).appendingPathComponent("/translations")
        
        let setupExpectation = expectation(description: "Set up offline routing")
        
        let directions = MapboxOfflineDirections(tilesPath: tilesPath, translationsPath: translationsPath, accessToken: "foo") { (numberOfTiles) in
            XCTAssertEqual(numberOfTiles, 5)
            setupExpectation.fulfill()
        }
        
        wait(for: [setupExpectation], timeout: 2)
        
        // Coordinates in SF
        let coordinates = [CLLocationCoordinate2D(latitude: 37.7870, longitude: -122.4261),
                           CLLocationCoordinate2D(latitude: 37.7805, longitude: -122.4073)]
        
        let options = NavigationRouteOptions(coordinates: coordinates, profileIdentifier: .automobile)
        let calculateRouteExpectation = expectation(description: "Calculate route offline")
        
        directions.calculateOffline(options) { (waypoints, routes, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(routes)
            XCTAssertNil(waypoints)
            calculateRouteExpectation.fulfill()
        }
        
        wait(for: [calculateRouteExpectation], timeout: 2)
    }
}
