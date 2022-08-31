import XCTest
import CoreLocation
import CarPlay
@testable import MapboxCoreNavigation
@testable import MapboxNavigation
@testable import MapboxDirections
@_spi(Restricted) @testable import MapboxMaps
import SnapshotTesting

class MapboxNavigationTests: XCTestCase {
    
    var navigationMapView: NavigationMapView!
    
    override func setUpWithError() throws {
        navigationMapView = NavigationMapView(frame: UIScreen.main.bounds)
        
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let rootViewController: UIViewController?
        if #available(iOS 15.0, *) {
            rootViewController = windowScene?.keyWindow?.rootViewController
        } else {
            rootViewController = windowScene?.windows.filter({ $0.isKeyWindow }).first?.rootViewController
        }
        
        guard let rootViewController = rootViewController else {
            XCTFail("Root view controller should be valid.")
            return
        }
        
        rootViewController.view.addSubview(navigationMapView)
    }
    
    override func tearDownWithError() throws {
        navigationMapView.removeFromSuperview()
    }
    
    func testNavigationMapEvents() {
        let timeout: TimeInterval = 10.0
        
        navigationMapView.mapView.mapboxMap.onNext(event: .mapLoadingError) { event in
            XCTFail("Failed to load map with error: \(String(describing: event.payload))")
        }
        
        let styleLoadedExpectation = XCTestExpectation(description: "Style loaded expectation.")
        navigationMapView.mapView.mapboxMap.onNext(event: .styleLoaded) { _ in
            styleLoadedExpectation.fulfill()
        }
        wait(for: [styleLoadedExpectation], timeout: timeout)
        
        let mapLoadedExpectation = XCTestExpectation(description: "Map loaded expectation.")
        navigationMapView.mapView.mapboxMap.onNext(event: .mapLoaded) { _ in
            mapLoadedExpectation.fulfill()
        }
        wait(for: [mapLoadedExpectation], timeout: timeout)
    }
    
    func routes(for coordinates: [CLLocationCoordinate2D], routeName: String) -> [Route] {
        let navigationRouteOptions = NavigationRouteOptions(coordinates: coordinates)
        
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = navigationRouteOptions
        
        let data = JSONFromFile(name: routeName)
        
        do {
            let routes = try decoder.decode([Route].self, from: data)
            return routes
        } catch {
            XCTFail("Error occured while decoding routes: \(error.localizedDescription).")
        }
        
        return []
    }
    
    func wait(timeout: TimeInterval = 1.0) {
        let waitExpectation = expectation(description: "Wait expectation.")
        _ = XCTWaiter.wait(for: [waitExpectation], timeout: timeout)
    }
    
    func JSONFromFile(name: String) -> Data {
        guard let path = Bundle.main.path(forResource: name, ofType: "json") else {
            preconditionFailure("File \(name) not found.")
        }
        
        guard let data = NSData(contentsOfFile: path) as Data? else {
            preconditionFailure("No data found at \(path).")
        }
        
        return data
    }
    
    func assertImageSnapshot<Value, Format>(matching value: @autoclosure () throws -> Value,
                                            as snapshotting: Snapshotting<Value, Format>,
                                            named name: String? = nil,
                                            record recording: Bool = false,
                                            timeout: TimeInterval = 5,
                                            file: StaticString = #file,
                                            testName: String = #function,
                                            line: UInt = #line) {
        let fileUrl = URL(fileURLWithPath: "\(file)", isDirectory: false)
        let snapshotDeviceName: String = ProcessInfo.processInfo
            .environment["SIMULATOR_MODEL_IDENTIFIER"]!
            .replacingOccurrences(of: ",", with: "_")
        let operatingSystemVersion: String = UIDevice.current.systemVersion
        let fileName = fileUrl.deletingPathExtension().lastPathComponent
        
        let snapshotDirectoryUrl = fileUrl
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent(snapshotDeviceName)
            .appendingPathComponent(operatingSystemVersion)
            .appendingPathComponent(fileName)
        
        guard let message = verifySnapshot(matching: try value(),
                                           as: snapshotting,
                                           named: name,
                                           record: recording,
                                           snapshotDirectory: snapshotDirectoryUrl.path,
                                           timeout: timeout,
                                           file: file,
                                           testName: testName,
                                           line: line) else {
            return
        }
        
        XCTFail(message, file: file, line: line)
    }
}
