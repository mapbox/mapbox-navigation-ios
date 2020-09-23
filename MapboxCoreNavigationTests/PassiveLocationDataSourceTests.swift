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

        let bundle = Bundle(for: Fixture.self)
        let filePathURL: URL = URL(fileURLWithPath: bundle.bundlePath.appending("/tiles/liechtenstein"))

        // Create PassiveLocationDataSource and configure it with the tiles version (version is used to find the tiles in the cache folder)
        let locationManager = PassiveLocationDataSource()
        do {
            try locationManager.configureNavigator(withTilesVersion: tilesVersion)
        } catch {
            XCTAssertTrue(false)
        }

        locationManager.configureNavigator(withURL: filePathURL, tilesVersion: tilesVersion)

        let locationUpdateExpectation = expectation(description: "Location manager takes some time to start mapping locations to a road graph")
        locationUpdateExpectation.expectedFulfillmentCount = 1
        
        let road = Road(from: CLLocationCoordinate2D(latitude: 47.207966, longitude: 9.527012), to: CLLocationCoordinate2D(latitude: 47.209518, longitude: 9.522167))
        let delegate = Delegate(road: road, locationUpdateExpectation: locationUpdateExpectation)
        let date = Date()
        locationManager.updateLocation(CLLocation(latitude: 47.208674, longitude: 9.524650, timestamp: date.addingTimeInterval(-5)))
        locationManager.delegate = delegate
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            locationManager.updateLocation(CLLocation(latitude: 47.208943, longitude: 9.524707, timestamp: date.addingTimeInterval(-4)))
            locationManager.updateLocation(CLLocation(latitude: 47.209082, longitude: 9.524319, timestamp: date.addingTimeInterval(-3)))
            locationManager.updateLocation(CLLocation(latitude: 47.209229, longitude: 9.523838, timestamp: date.addingTimeInterval(-2)))
            locationManager.updateLocation(CLLocation(latitude: 47.209612, longitude: 9.522629, timestamp: date.addingTimeInterval(-1)))
            locationManager.updateLocation(CLLocation(latitude: 47.209842, longitude: 9.522377, timestamp: date.addingTimeInterval(0)))

            locationUpdateExpectation.fulfill()
        }
        wait(for: [locationUpdateExpectation], timeout: 5)
    }
}

private extension CLLocation {
    convenience init(latitude: CLLocationDegrees, longitude: CLLocationDegrees, timestamp: Date) {
        self.init(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: timestamp
        )
    }
}
