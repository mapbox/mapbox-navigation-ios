import XCTest
import FBSnapshotTestCase
import Turf
import TestHelper
import MapboxDirections
@testable import MapboxCoreNavigation
@testable import MapboxNavigation


class HistoricRouteProgressTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        recordMode = false
        agnosticOptions = [.OS, .device]
    }

    func testHistoricRouteProgress() {
        
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
        
        NavigationDirections.unpackTilePack(at: packURL, outputDirectoryURL: outputDirectoryURL, progressHandler: { (totalBytes, unpackedBytes) in
            
        }) { (result, error) in
            XCTAssertEqual(result, 5)
            XCTAssertNil(error)
            unpackExpectation.fulfill()
        }
        
        wait(for: [unpackExpectation], timeout: 10)
        
        let configureExpectation = self.expectation(description: "Configure router with unpacked tar")
        
        let directions = NavigationDirections(accessToken: "foo")
        directions.configureRouter(tilesURL: outputDirectoryURL) { (numberOfTiles) in
            XCTAssertEqual(numberOfTiles, 5)
            configureExpectation.fulfill()
        }
        
        wait(for: [configureExpectation], timeout: 5)
        
        //let thirdWp = CLLocationCoordinate2D(latitude: 47.214241, longitude: 9.522299)
        let coordinates = [CLLocationCoordinate2D(latitude: 47.210182, longitude: 9.517212),
                           CLLocationCoordinate2D(latitude: 47.212353, longitude: 9.512570)]
        let options = NavigationRouteOptions(coordinates: coordinates, profileIdentifier: .automobile)
        
        let calculateExpectation = self.expectation(description: "Calculate route expectation")
        var route: Route!
        directions.calculate(options, offline: true) { (waypoints, routes, error) in
            route = routes!.first!
        }
        
        wait(for: [calculateExpectation], timeout: 1)
        
        let view = RoutePlotter(frame: CGRect(origin: .zero, size: CGSize(width: 2000, height: 2000)))
        view.route = route
        
        let trace = Fixture.locations(from: "historic-route-progress.trace")
        let traceCoordinates = trace.map { CLLocationCoordinate2D(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) }
        
        let linePlotter = LinePlotter.init(coordinates: traceCoordinates, color: .gray, lineWidth: 6, drawIndexesAsText: false)
        view.linePlotters = [linePlotter]
        
        verify(view)
    }
}
