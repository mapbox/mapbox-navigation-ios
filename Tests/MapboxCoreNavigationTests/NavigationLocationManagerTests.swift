import XCTest
import CoreLocation
import MapboxCoreNavigation

class NavigationLocationManagerTests: XCTestCase {
    func testNavigationLocationManagerDefaultAccuracy() {
        let locationManager = NavigationLocationManager()
        XCTAssertEqual(locationManager.desiredAccuracy, kCLLocationAccuracyBest)
    }
}
