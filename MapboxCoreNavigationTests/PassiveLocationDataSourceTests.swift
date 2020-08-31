import Foundation
import MapboxNavigationNative
import TestHelper
import XCTest
@testable import MapboxCoreNavigation
import MapboxAccounts

class Road {
    let from: CLLocationCoordinate2D
    let to: CLLocationCoordinate2D
    let length: Double

    init(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        self.from = from
        self.to = to
        self.length = (to - from).length()
    }

    func whichCloser(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return proximity(of: a) > proximity(of: b) ? b : a
    }

    func proximity(of: CLLocationCoordinate2D) -> Double {
        return ((of - from).length() + (of - to).length()) / length
    }
}

extension CLLocationCoordinate2D {
    static func -(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: a.latitude - b.latitude, longitude: a.longitude - b.longitude)
    }

    func length() -> Double {
        return sqrt(latitude * latitude + longitude * longitude)
    }
}

class PassiveLocationDataSourceTests: XCTestCase {
    class Delegate: PassiveLocationDataSourceDelegate {
        let road: Road
        let locationUpdateExpectation: XCTestExpectation
        
        init(road: Road, locationUpdateExpectation: XCTestExpectation) {
            self.road = road
            self.locationUpdateExpectation = locationUpdateExpectation
        }
        
        func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didUpdateLocation location: CLLocation, rawLocation: CLLocation) {
            print("Got location: \(rawLocation.coordinate.latitude), \(rawLocation.coordinate.longitude) → \(location.coordinate.latitude), \(location.coordinate.longitude)")
            print("Value: \(road.proximity(of: location.coordinate)) should be less \(road.proximity(of: rawLocation.coordinate))")

            XCTAssert(road.proximity(of: location.coordinate) < road.proximity(of: rawLocation.coordinate), "Raw Location wasn't mapped to a road")
        }
        
        func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didUpdateHeading newHeading: CLHeading) {
        }
        
        func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didFailWithError error: Error) {
        }
    }
    
    func testManualLocations() {
        let tilesVersion = "preloadedtiles" // any string

        // Copy tiles to the cache directory, tiles should be placed in a folder with name
        guard var tilesCacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            preconditionFailure("No Caches directory to create the tile directory inside")
        }
        if let bundleIdentifier = Bundle.main.bundleIdentifier ?? Bundle.mapboxCoreNavigation.bundleIdentifier {
            tilesCacheURL.appendPathComponent(bundleIdentifier, isDirectory: true)
        }
        tilesCacheURL.appendPathComponent(".mapbox", isDirectory: true)
        tilesCacheURL.appendPathComponent(tilesVersion, isDirectory: true)
        let bundle = Bundle(for: Fixture.self)
        let filePathURL: URL = URL(fileURLWithPath: bundle.bundlePath.appending("/tiles/liechtenstein"))
        let fileManager = FileManager.default
        var isDir : ObjCBool = false
        if !fileManager.fileExists(atPath: tilesCacheURL.path, isDirectory:&isDir) {
            do {
                try fileManager.copyItem(atPath: filePathURL.path, toPath: tilesCacheURL.path)
            }catch let error{
                print(error.localizedDescription)
            }
        }

        // Create PassiveLocationDataSource and configure it with the tiles version (version is used to find the tiles in the cache folder)
        let locationManager = PassiveLocationDataSource()
        do {
            try locationManager.configureNavigator(withTilesVersion: tilesVersion)
        } catch {
            XCTAssertTrue(false)
        }
        
        let locationUpdateExpectation = expectation(description: "Location manager takes some time to start mapping locations to a road graph")
        locationUpdateExpectation.expectedFulfillmentCount = 1
        
        let road = Road(from: CLLocationCoordinate2D(latitude: 47.207966, longitude: 9.527012), to: CLLocationCoordinate2D(latitude: 47.209518, longitude: 9.522167))
        let delegate = Delegate(road: road, locationUpdateExpectation: locationUpdateExpectation)
        locationManager.updateLocation(CLLocation(latitude: 47.208674, longitude: 9.524650))
        locationManager.delegate = delegate
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            locationManager.updateLocation(CLLocation(latitude: 47.208943, longitude: 9.524707))
            locationManager.updateLocation(CLLocation(latitude: 47.209082, longitude: 9.524319))
            locationManager.updateLocation(CLLocation(latitude: 47.209229, longitude: 9.523838))
            locationManager.updateLocation(CLLocation(latitude: 47.209612, longitude: 9.522629))
            locationManager.updateLocation(CLLocation(latitude: 47.209842, longitude: 9.522377))
            locationUpdateExpectation.fulfill()
        }
        wait(for: [locationUpdateExpectation], timeout: 5)
    }
}
