import XCTest
import MapboxDirections
import TestHelper
@testable import MapboxCoreNavigation


class OfflineRoutingTests: XCTestCase {
    
    func testOfflineDirections() {
        
        let bundle = Bundle(for: Fixture.self)
        let tilesURL = URL(fileURLWithPath: bundle.bundlePath.appending("/tiles/liechtenstein"))
        
        let setupExpectation = expectation(description: "Set up offline routing")
        
        let directions = NavigationDirections(accessToken: "foo")
        directions.configureRouter(tilesURL: tilesURL) { (numberOfTiles) in
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
        
        directions.calculate(options, offline: true) { (waypoints, routes, error) in
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
        let tilesURL = URL(fileURLWithPath: bundle.bundlePath).appendingPathComponent("/routing/liechtenstein")
        
        let setupExpectation = expectation(description: "Set up offline routing")
        
        let directions = NavigationDirections(accessToken: "foo")
        directions.configureRouter(tilesURL: tilesURL) { (numberOfTiles) in
            XCTAssertEqual(numberOfTiles, 5)
            setupExpectation.fulfill()
        }
        
        wait(for: [setupExpectation], timeout: 2)
        
        // Coordinates in SF
        let coordinates = [CLLocationCoordinate2D(latitude: 37.7870, longitude: -122.4261),
                           CLLocationCoordinate2D(latitude: 37.7805, longitude: -122.4073)]
        
        let options = NavigationRouteOptions(coordinates: coordinates, profileIdentifier: .automobile)
        let calculateRouteExpectation = expectation(description: "Calculate route offline")
        
        directions.calculate(options, offline: true) { (waypoints, routes, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.localizedDescription, "No suitable edges near location")
            XCTAssertNil(routes)
            XCTAssertNil(waypoints)
            calculateRouteExpectation.fulfill()
        }
        
        wait(for: [calculateRouteExpectation], timeout: 2)
    }
    
    func testUnpackTilePack() {
        
        let bundle = Bundle(for: Fixture.self)
        let readonlyPackURL = URL(fileURLWithPath: bundle.path(forResource: "li", ofType: "tar")!)
        
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        
        // Copy the read-only tar file so navigator can consume it
        let data = try! Data(contentsOf: readonlyPackURL)
        let packURL = URL(fileURLWithPath: documentDirectory, isDirectory: true).appendingPathComponent(readonlyPackURL.lastPathComponent)
        try! data.write(to: packURL)
        
        let outputDirectory = URL(fileURLWithPath: documentDirectory, isDirectory: true).appendingPathComponent("tiles/test")
        try? FileManager.default.createDirectory(atPath: outputDirectory.path, withIntermediateDirectories: true, attributes: nil)
        
        var progressUpdates = 0
        let unpackExpectation = self.expectation(description: "Tar file should be unpacked")
        let progressExpectation = self.expectation(description: "Progress should be reported")
        
        NavigationDirections.unpackTilePack(at: packURL, outputDirectory: outputDirectory, progressHandler: { (totalBytes, unpackedBytes) in
            
            progressUpdates += 1
            
            if (progressUpdates >= 2) {
                progressExpectation.fulfill()
            }
            
        }) { (result, error) in
            XCTAssertEqual(result, 5)
            XCTAssertNil(error)
            unpackExpectation.fulfill()
        }
        
        wait(for: [progressExpectation, unpackExpectation], timeout: 60 * 2)
        
        let configureExpectation = self.expectation(description: "Configure router with unpacked tar")
        
        let directions = NavigationDirections(accessToken: "foo")
        directions.configureRouter(tilesURL: outputDirectory) { (numberOfTiles) in
            XCTAssertEqual(numberOfTiles, 8)
            configureExpectation.fulfill()
        }
        
        wait(for: [configureExpectation], timeout: 60)
    }
}
