import XCTest
import Turf
import MapboxMaps

@testable import MapboxDirections
@testable import TestHelper
@testable import MapboxCoreNavigation
@testable import MapboxNavigation

class NavigationCameraTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNavigationCameraDefaultState() {
        // By default Navigation Camera moves to `NavigationCameraState.following` state.
        let navigationMapView = NavigationMapView(frame: .zero)
        XCTAssertEqual(navigationMapView.navigationCamera.state, .following)
        
        let route = Fixture.route(from: jsonFileName,
                                  options: routeOptions)
        
        let navigationViewController = NavigationViewController(for: route,
                                                                routeIndex: 0,
                                                                routeOptions: routeOptions)
        
        XCTAssertEqual(navigationViewController.navigationMapView?.navigationCamera.state, .following)
    }
}
