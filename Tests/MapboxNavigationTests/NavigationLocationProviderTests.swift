import XCTest
import MapboxMaps
@testable import MapboxNavigation
import TestHelper

class NavigationLocationProviderTests: TestCase {
    var navigationMapView: NavigationMapView!
    
    override func setUp() {
        super.setUp()
        navigationMapView = NavigationMapView(frame: .zero)
    }
    
    override func tearDown() {
        navigationMapView = nil
        super.tearDown()
    }
    
    func testOverriddenLocationProviderUpdateLocations() {
        let navigationLocationManagerStub = NavigationLocationManagerStub()
        let navigationLocationProviderStub = NavigationLocationProvider(locationManager: navigationLocationManagerStub)
        let location = CLLocation(latitude: 0, longitude: 0)
        
        navigationMapView.mapView.location.overrideLocationProvider(with: navigationLocationProviderStub)
        navigationLocationProviderStub.didUpdateLocations(locations: [location])
        
        XCTAssert(navigationMapView.mapView?.location.locationProvider is NavigationLocationProvider, "Failed to override mapView location provider.")
        XCTAssertEqual(navigationMapView.mapView.location.latestLocation?.coordinate, location.coordinate, "Failed to update mapView location.")
    }
}
