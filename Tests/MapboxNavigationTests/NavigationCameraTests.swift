import XCTest
import Turf
import MapboxMaps

@testable import MapboxDirections
@testable import TestHelper
@testable import MapboxCoreNavigation
@testable import MapboxNavigation

class ViewportDataSourceMock: ViewportDataSource {
    
    public weak var delegate: ViewportDataSourceDelegate?
    
    public var followingMobileCamera: CameraOptions = CameraOptions()
    
    public var followingCarPlayCamera: CameraOptions = CameraOptions()
    
    public var overviewMobileCamera: CameraOptions = CameraOptions()
    
    public var overviewCarPlayCamera: CameraOptions = CameraOptions()
    
    weak var mapView: MapView?
    
    public required init(_ mapView: MapView) {
        self.mapView = mapView
        
        followingMobileCamera.center = CLLocationCoordinate2D(latitude: 37.788443,
                                                              longitude: -122.4020258)
        followingMobileCamera.bearing = 0.0
        followingMobileCamera.padding = .zero
        followingMobileCamera.zoom = 15.0
        followingMobileCamera.pitch = 45.0
        
        let cameraOptions = [
            CameraOptions.followingMobileCamera: followingMobileCamera
        ]
        
        delegate?.viewportDataSource(self, didUpdate: cameraOptions)
    }
}

class CameraStateTransitionMock: CameraStateTransition {
    
    weak var mapView: MapView?
    
    let duration = 0.1
    
    let curve: UIView.AnimationCurve = .linear
    
    required init(_ mapView: MapView) {
        self.mapView = mapView
    }
    
    func transitionToFollowing(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void)) {
        mapView?.camera.ease(to: cameraOptions,
                             duration: duration,
                             curve: curve,
                             completion: { _ in
                                completion()
                             })
    }
    
    func transitionToOverview(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void)) {
        mapView?.camera.ease(to: cameraOptions,
                             duration: duration,
                             curve: curve,
                             completion: { _ in
                                completion()
                             })
    }
    
    func updateForFollowing(_ cameraOptions: CameraOptions) {
        mapView?.camera.ease(to: cameraOptions,
                             duration: duration,
                             curve: curve,
                             completion: nil)
    }
    
    func updateForOverview(_ cameraOptions: CameraOptions) {
        mapView?.camera.ease(to: cameraOptions,
                             duration: duration,
                             curve: curve,
                             completion: nil)
    }
    
    func cancelPendingTransition() {
        mapView?.camera.cancelAnimations()
    }
}

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
    
    func testNavigationCameraOverviewState() {
        let navigationMapView = NavigationMapView(frame: .zero)
        
        navigationMapView.navigationCamera.viewportDataSource = ViewportDataSourceMock(navigationMapView.mapView)
        navigationMapView.navigationCamera.cameraStateTransition = CameraStateTransitionMock(navigationMapView.mapView)
        
        // By default Navigation Camera moves to `NavigationCameraState.following` state.
        XCTAssertEqual(navigationMapView.navigationCamera.state, .following)
        
        // After calling `NavigationCamera.moveToOverview()` camera state should be set
        // to `NavigationCameraState.transitionToOverview` first, only after finishing transition
        // to `NavigationCameraState.overview`.
        navigationMapView.navigationCamera.moveToOverview()
        XCTAssertEqual(navigationMapView.navigationCamera.state, .transitionToOverview)
        
        // Navigation camera transition lasts 0.1 seconds. At the end of transition it is expected
        // that camera state is `NavigationCameraState.overview`.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(navigationMapView.navigationCamera.state, .overview)
            
            // All further calls to `NavigationCamera.moveToOverview()` should not change camera state.
            navigationMapView.navigationCamera.moveToOverview()
            XCTAssertEqual(navigationMapView.navigationCamera.state, .overview)
        }
    }
    
    func testNavigationCameraIdleState() {
        // By default Navigation Camera moves to `NavigationCameraState.following` state.
        let navigationMapView = NavigationMapView(frame: .zero)
        XCTAssertEqual(navigationMapView.navigationCamera.state, .following)
        
        // After calling `NavigationCamera.stop()` camera state should be set to
        // `NavigationCameraState.idle`.
        navigationMapView.navigationCamera.stop()
        XCTAssertEqual(navigationMapView.navigationCamera.state, .idle)
        
        // All further calls to `NavigationCamera.stop()` should not change camera state.
        navigationMapView.navigationCamera.stop()
        XCTAssertEqual(navigationMapView.navigationCamera.state, .idle)
    }
}
