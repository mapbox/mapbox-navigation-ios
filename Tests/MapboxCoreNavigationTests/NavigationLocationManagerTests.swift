import XCTest
import CoreLocation
import MapboxCoreNavigation
import TestHelper

class NavigationLocationManagerTests: TestCase {
    func testNavigationLocationManagerDefaultAccuracy() {
        let locationManager = NavigationLocationManager()
        XCTAssertEqual(locationManager.desiredAccuracy, kCLLocationAccuracyBest)
    }
}
