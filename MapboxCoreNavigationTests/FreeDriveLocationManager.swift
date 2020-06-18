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

class FreeDriveLocationManagerTests: XCTestCase {
    class LocationsObserver: NSObject, CLLocationManagerDelegate {
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.first else { return }
            print("Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }

    func testFreeDrive() {
        let locationManager = FreeDriveLocationManager()
        locationManager.setCustomLocation(CLLocation(latitude: 47.208674, longitude: 9.524650))

        let road = Road(from: CLLocationCoordinate2D(latitude: 47.207966, longitude: 9.527012), to: CLLocationCoordinate2D(latitude: 47.209518, longitude: 9.522167))

        let expectation = XCTestExpectation(description: "")

        _ = locationManager.debugView() { rawLocation, location in
            print("Got locations: (\(rawLocation.latitude), \(rawLocation.longitude)) -> (\(location.latitude), \(location.longitude))")
            print("Value: \(road.proximity(of: location)) < \(road.proximity(of: rawLocation))")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            locationManager.setCustomLocation(CLLocation(latitude: 47.208943, longitude: 9.524707))
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                locationManager.setCustomLocation(CLLocation(latitude: 47.209082, longitude: 9.524319))
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    locationManager.setCustomLocation(CLLocation(latitude: 47.209229, longitude: 9.523838))
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                        locationManager.setCustomLocation(CLLocation(latitude: 47.209612, longitude: 9.522629))
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                            locationManager.setCustomLocation(CLLocation(latitude: 47.209842, longitude: 9.522377))
                            XCTAssert(true)
                            expectation.fulfill()
                        }
                    }
                }
            }
        }
        wait(for: [expectation], timeout: 20.1)
    }
}
