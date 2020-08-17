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
            print("Value: \(road.proximity(of: location.coordinate)) < \(road.proximity(of: rawLocation.coordinate))")
            locationUpdateExpectation.fulfill()
        }
        
        func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didUpdateHeading newHeading: CLHeading) {
        }
        
        func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didFailWithError error: Error) {
        }
    }
    
    func testManualLocations() {
//        let directions = DirectionsSpy()
        let locationManager = PassiveLocationDataSource()
        
        let startingExpectation = expectation(description: "Location manager should start without an error")
        locationManager.startUpdatingLocation { (error) in
            XCTAssertNil(error)
            startingExpectation.fulfill()
        }
        wait(for: [startingExpectation], timeout: 2)
        
        // FIXME: Starting the location manager should automatically configure the navigator.
        XCTAssertNoThrow(try locationManager.configureNavigator(withTilesVersion: "1234"))
        
        let locationUpdateExpectation = expectation(description: "Location manager should respond to every manual location update")
        locationUpdateExpectation.expectedFulfillmentCount = 5
        
        let road = Road(from: CLLocationCoordinate2D(latitude: 47.207966, longitude: 9.527012), to: CLLocationCoordinate2D(latitude: 47.209518, longitude: 9.522167))
        let delegate = Delegate(road: road, locationUpdateExpectation: locationUpdateExpectation)
        locationManager.delegate = delegate
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
            locationManager.updateLocation(CLLocation(latitude: 47.208674, longitude: 9.524650))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(25)) {
            locationManager.updateLocation(CLLocation(latitude: 47.208943, longitude: 9.524707))
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                locationManager.updateLocation(CLLocation(latitude: 47.209082, longitude: 9.524319))
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    locationManager.updateLocation(CLLocation(latitude: 47.209229, longitude: 9.523838))
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                        locationManager.updateLocation(CLLocation(latitude: 47.209612, longitude: 9.522629))
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                            locationManager.updateLocation(CLLocation(latitude: 47.209842, longitude: 9.522377))
                        }
                    }
                }
            }
        }
        wait(for: [locationUpdateExpectation], timeout: 50.1)
    }
}
