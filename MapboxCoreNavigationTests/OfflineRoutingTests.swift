import XCTest
import MapboxDirections
import TestHelper
@testable import MapboxCoreNavigation

class OfflineRoutingTests: XCTestCase {
    func skipped_testOfflineDirections() {
        let bundle = Bundle(for: Fixture.self)
        let tilesURL = URL(fileURLWithPath: bundle.bundlePath.appending("/tiles/liechtenstein"))

        let setupExpectation = expectation(description: "Set up offline routing")

        let directions = NavigationDirections(credentials: Fixture.credentials)
        
        directions.configureRouter(tilesURL: tilesURL) { (numberOfTiles) in
            // TODO: Revise this check. As of navigation native 14.1.4 numberOfTiles is always equal to 0.
            XCTAssertEqual(numberOfTiles, 0)
            setupExpectation.fulfill()
        }

        wait(for: [setupExpectation], timeout: 2)

        // Coordinates within Liechtenstein
        let coordinates = [CLLocationCoordinate2D(latitude: 47.208674, longitude: 9.524650),
                           CLLocationCoordinate2D(latitude: 47.211247, longitude: 9.526666)]

        let options = NavigationRouteOptions(coordinates: coordinates, profileIdentifier: .automobile)
        let calculateRouteExpectation = expectation(description: "Calculate route offline")
        var possibleRoute: Route?

        directions.calculate(options, offline: true) { (session, result) in
            switch result {
            case let .failure(error):
                XCTFail("Unexpected Failure: \(error)")
                
            case let .success(response):
                XCTAssertNotNil(response.routes)
                XCTAssertNotNil(response.waypoints)
                possibleRoute = response.routes!.first!
                calculateRouteExpectation.fulfill()
            }
        }

        wait(for: [calculateRouteExpectation], timeout: 2)

        guard let route = possibleRoute else {
            XCTFail("No route returned")
            return
        }
        
        XCTAssertEqual(route.shape!.coordinates.count, 47)
    }
    
    func testOfflineDirectionsError() {
        let bundle = Bundle(for: Fixture.self)
        let tilesURL = URL(fileURLWithPath: bundle.bundlePath).appendingPathComponent("/tiles/liechtenstein")
        
        let setupExpectation = expectation(description: "Set up offline routing")
        
        let directions = NavigationDirections(credentials: Fixture.credentials)
        directions.configureRouter(tilesURL: tilesURL) { (numberOfTiles) in
            // TODO: Revise this check. As of navigation native 14.1.4 numberOfTiles is always equal to 0.
            XCTAssertEqual(numberOfTiles, 0)
            setupExpectation.fulfill()
        }
        
        wait(for: [setupExpectation], timeout: 2)
        
        // Coordinates in SF
        let coordinates = [CLLocationCoordinate2D(latitude: 37.7870, longitude: -122.4261),
                           CLLocationCoordinate2D(latitude: 37.7805, longitude: -122.4073)]
        
        let options = NavigationRouteOptions(coordinates: coordinates, profileIdentifier: .automobile)
        let calculateRouteExpectation = expectation(description: "Calculate route offline")
        
        directions.calculate(options, offline: true) { (session, response) in
            guard case let .failure(error) = response else {
                XCTFail("Unexpected Success")
                return
            }
            
            guard case let .standard(directionsError) = error else {
                XCTFail("Wrong error type.")
                return
            }
            
            XCTAssertEqual(directionsError, .unableToRoute)
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
        
        let outputDirectoryURL = URL(fileURLWithPath: documentDirectory, isDirectory: true).appendingPathComponent("tiles/test")
        try? FileManager.default.createDirectory(atPath: outputDirectoryURL.path, withIntermediateDirectories: true, attributes: nil)
        
        let unpackExpectation = self.expectation(description: "Tar file should be unpacked")
        let progressExpectation = self.expectation(description: "Progress should be reported")
        progressExpectation.expectedFulfillmentCount = 2
        
        NavigationDirections.unpackTilePack(at: packURL, outputDirectoryURL: outputDirectoryURL, progressHandler: { (totalBytes, unpackedBytes) in
            progressExpectation.fulfill()
        }) { (result, error) in
            XCTAssertEqual(result, 5)
            XCTAssertNil(error)
            unpackExpectation.fulfill()
        }
        
        wait(for: [progressExpectation, unpackExpectation], timeout: 60 * 2)
        
        let configureExpectation = self.expectation(description: "Configure router with unpacked tar")
        
        let directions = NavigationDirections(credentials: Fixture.credentials)
        directions.configureRouter(tilesURL: outputDirectoryURL) { (numberOfTiles) in
            // TODO: Revise this check. As of navigation native 14.1.4 numberOfTiles is always equal to 0.
            XCTAssertEqual(numberOfTiles, 0)
            configureExpectation.fulfill()
        }
        
        wait(for: [configureExpectation], timeout: 60)
    }
}
