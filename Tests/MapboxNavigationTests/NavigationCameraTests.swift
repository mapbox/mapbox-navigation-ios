import XCTest
import Turf
import MapboxMaps
import MapboxDirections

@testable import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

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
    
    required init(_ mapView: MapView) {
        self.mapView = mapView
    }
    
    func transitionToFollowing(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void)) {
        // Delay is used to be able to verify whether `NavigationCameraState` changes from
        // `NavigationCameraState.transitionToFollowing` to `NavigationCameraState.following`.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion()
        }
    }
    
    func transitionToOverview(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void)) {
        // Delay is used to be able to verify whether `NavigationCameraState` changes from
        // `NavigationCameraState.transitionToOverview` to `NavigationCameraState.overview`.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion()
        }
    }
    
    func update(to cameraOptions: CameraOptions, state: NavigationCameraState) {
        
    }
    
    func cancelPendingTransition() {
        mapView?.camera.cancelAnimations()
    }
}

class ViewportDataSourceDelegateMock: ViewportDataSourceDelegate {
    
    var cameraOptions: [String: CameraOptions]?
    
    func viewportDataSource(_ dataSource: ViewportDataSource, didUpdate cameraOptions: [String: CameraOptions]) {
        self.cameraOptions = cameraOptions
    }
}

class NavigationCameraTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNavigationMapViewCameraType() {
        var navigationMapView = NavigationMapView(frame: .zero)
        XCTAssertEqual(navigationMapView.navigationCamera.type, .mobile)
        
        navigationMapView = NavigationMapView(frame: .zero, navigationCameraType: .carPlay)
        XCTAssertEqual(navigationMapView.navigationCamera.type, .carPlay)
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
    
    func testNavigationCameraFollowingState() {
        let navigationMapView = NavigationMapView(frame: .zero)
        
        navigationMapView.navigationCamera.viewportDataSource = ViewportDataSourceMock(navigationMapView.mapView)
        navigationMapView.navigationCamera.cameraStateTransition = CameraStateTransitionMock(navigationMapView.mapView)
        
        // By default Navigation Camera moves to `NavigationCameraState.following` state.
        XCTAssertEqual(navigationMapView.navigationCamera.state, .following)
        
        let overviewExpectation = expectation(description: "Overview camera expectation.")
        
        // After calling `NavigationCamera.moveToOverview()` camera state should be set
        // to `NavigationCameraState.transitionToOverview` first, only after finishing transition
        // to `NavigationCameraState.overview`.
        navigationMapView.navigationCamera.moveToOverview {
            overviewExpectation.fulfill()
        }
        XCTAssertEqual(navigationMapView.navigationCamera.state, .transitionToOverview)
        
        wait(for: [overviewExpectation], timeout: 1.0)
        
        // Navigation camera transition lasts 0.1 seconds. At the end of transition it is expected
        // that camera state is `NavigationCameraState.overview`.
        XCTAssertEqual(navigationMapView.navigationCamera.state, .overview)
        
        let followingExpectation = expectation(description: "Following camera expectation.")
        
        // After calling `NavigationCamera.follow()` camera state should be set
        // to `NavigationCameraState.transitionToFollowing` first, only after finishing transition
        // to `NavigationCameraState.following`.
        navigationMapView.navigationCamera.follow {
            followingExpectation.fulfill()
        }
        XCTAssertEqual(navigationMapView.navigationCamera.state, .transitionToFollowing)
        
        wait(for: [followingExpectation], timeout: 1.0)
        
        XCTAssertEqual(navigationMapView.navigationCamera.state, .following)
    }
    
    func testNavigationCameraOverviewStateDoesntChange() {
        let navigationMapView = NavigationMapView(frame: .zero)
        
        navigationMapView.navigationCamera.viewportDataSource = ViewportDataSourceMock(navigationMapView.mapView)
        navigationMapView.navigationCamera.cameraStateTransition = CameraStateTransitionMock(navigationMapView.mapView)
        
        // By default Navigation Camera moves to `NavigationCameraState.following` state.
        XCTAssertEqual(navigationMapView.navigationCamera.state, .following)
        
        let overviewExpectation = expectation(description: "Overview camera expectation.")
        
        // After calling `NavigationCamera.moveToOverview()` camera state should be set
        // to `NavigationCameraState.transitionToOverview` first, only after finishing transition
        // to `NavigationCameraState.overview`.
        navigationMapView.navigationCamera.moveToOverview {
            overviewExpectation.fulfill()
        }
        XCTAssertEqual(navigationMapView.navigationCamera.state, .transitionToOverview)
        
        wait(for: [overviewExpectation], timeout: 1.0)
        
        // Navigation camera transition lasts 0.1 seconds. At the end of transition it is expected
        // that camera state is `NavigationCameraState.overview`.
        XCTAssertEqual(navigationMapView.navigationCamera.state, .overview)
        
        // All further calls to `NavigationCamera.moveToOverview()` should not change camera state and
        // will be executed right away.
        navigationMapView.navigationCamera.moveToOverview {
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
    
    func testViewportDataSourceDelegateForFreeDrive() {
        let navigationMapView = NavigationMapView(frame: .zero)
        
        // By default `NavigationViewportDataSource` listens to `Notification.Name.passiveLocationManagerDidUpdate`.
        let navigationViewportDataSource = navigationMapView.navigationCamera.viewportDataSource as? NavigationViewportDataSource
        
        let viewportDataSourceDelegateMock = ViewportDataSourceDelegateMock()
        navigationViewportDataSource?.delegate = viewportDataSourceDelegateMock
        
        let expectation = self.expectation(forNotification: .passiveLocationManagerDidUpdate,
                                           object: self) { _ in
            return true
        }
        
        let location = CLLocation(latitude: 37.112341, longitude: -122.1111678)
        let rawLocation = CLLocation(latitude: 37.788443, longitude: -122.4020258)
        
        let userInfo: [PassiveLocationManager.NotificationUserInfoKey: Any] = [
            .locationKey: location,
            .rawLocationKey: rawLocation
        ]
        
        // Send `Notification.Name.passiveLocationManagerDidUpdate` notification and make sure that
        // `CameraOptions`, which were generated by `NavigationViewportDataSource` are correct.
        NotificationCenter.default.post(name: .passiveLocationManagerDidUpdate,
                                        object: self,
                                        userInfo: userInfo)
        
        wait(for: [expectation], timeout: 1.0)
        
        // It is expected that `NavigationViewportDataSource` uses default values for `CameraOptions`
        // during free-drive. Location, snapped to the road network should be used instead of raw one.
        let expectedCoordinate = location.coordinate
        let expectedAnchor: CGPoint = .zero
        let expectedPadding: UIEdgeInsets = .zero
        let expectedAltitude = 4000.0
        let expectedBearing: Double = 0.0
        let expectedPitch: CGFloat = 0.0
        let expectedZoomLevel = CGFloat(ZoomLevelForAltitude(expectedAltitude,
                                                             navigationMapView.mapView.cameraState.pitch,
                                                             location.coordinate.latitude,
                                                             navigationMapView.mapView.bounds.size))
        
        let followingMobileCameraOptions = viewportDataSourceDelegateMock.cameraOptions?[CameraOptions.followingMobileCamera]
        XCTAssertEqual(followingMobileCameraOptions?.center, expectedCoordinate, "Center coordinates should be equal.")
        XCTAssertEqual(followingMobileCameraOptions?.anchor, expectedAnchor, "Anchors should be equal.")
        XCTAssertEqual(followingMobileCameraOptions?.padding, expectedPadding, "Paddings should be equal.")
        XCTAssertEqual(followingMobileCameraOptions?.bearing, expectedBearing, "Bearings should be equal.")
        XCTAssertEqual(followingMobileCameraOptions?.zoom, expectedZoomLevel, "Zooms should be equal.")
        XCTAssertEqual(followingMobileCameraOptions?.pitch, expectedPitch, "Pitches should be equal.")
        
        let followingCarPlayCameraOptions = viewportDataSourceDelegateMock.cameraOptions?[CameraOptions.followingCarPlayCamera]
        XCTAssertEqual(followingCarPlayCameraOptions?.center, expectedCoordinate, "Center coordinates should be equal.")
        XCTAssertEqual(followingCarPlayCameraOptions?.anchor, expectedAnchor, "Anchors should be equal.")
        XCTAssertEqual(followingCarPlayCameraOptions?.padding, expectedPadding, "Paddings should be equal.")
        XCTAssertEqual(followingCarPlayCameraOptions?.bearing, expectedBearing, "Bearings should be equal.")
        XCTAssertEqual(followingCarPlayCameraOptions?.zoom, expectedZoomLevel, "Zooms should be equal.")
        XCTAssertEqual(followingCarPlayCameraOptions?.pitch, expectedPitch, "Pitches should be equal.")
        
        // In `NavigationCameraState.overview` state during free-drive navigation all properties of
        // `CameraOptions` should be `nil`.
        let overviewMobileCameraOptions = viewportDataSourceDelegateMock.cameraOptions?[CameraOptions.overviewMobileCamera]
        XCTAssertNil(overviewMobileCameraOptions?.center, "Center should be nil.")
        XCTAssertNil(overviewMobileCameraOptions?.anchor, "Anchor should be nil.")
        XCTAssertNil(overviewMobileCameraOptions?.padding, "Padding should be nil.")
        XCTAssertNil(overviewMobileCameraOptions?.bearing, "Bearing should be nil.")
        XCTAssertNil(overviewMobileCameraOptions?.zoom, "Zoom should be nil.")
        XCTAssertNil(overviewMobileCameraOptions?.pitch, "Pitch should be nil.")
        
        let overviewCarPlayCameraOptions = viewportDataSourceDelegateMock.cameraOptions?[CameraOptions.overviewCarPlayCamera]
        XCTAssertNil(overviewCarPlayCameraOptions?.center, "Center should be nil.")
        XCTAssertNil(overviewCarPlayCameraOptions?.anchor, "Anchor should be nil.")
        XCTAssertNil(overviewCarPlayCameraOptions?.padding, "Padding should be nil.")
        XCTAssertNil(overviewCarPlayCameraOptions?.bearing, "Bearing should be nil.")
        XCTAssertNil(overviewCarPlayCameraOptions?.zoom, "Zoom should be nil.")
        XCTAssertNil(overviewCarPlayCameraOptions?.pitch, "Pitch should be nil.")
    }
    
    func testViewportDataSourceDelegateForActiveGuidance() {
        let navigationMapView = NavigationMapView(frame: .zero)
        
        // Create new `NavigationViewportDataSource` instance, which listens to the
        // `Notification.Name.routeControllerProgressDidChange` notification, which is sent during
        // active guidance navigation.
        let navigationViewportDataSource = NavigationViewportDataSource(navigationMapView.mapView,
                                                                        viewportDataSourceType: .active)
        
        navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
        
        let viewportDataSourceDelegateMock = ViewportDataSourceDelegateMock()
        navigationMapView.navigationCamera.viewportDataSource.delegate = viewportDataSourceDelegateMock
        
        let origin = CLLocationCoordinate2DMake(37.765469, -122.415279)
        let destination = CLLocationCoordinate2DMake(37.767071968183814, -122.41340145370796)
        let routeOptions = NavigationRouteOptions(coordinates: [origin, destination])
        
        // Load previously serialized `Route` object in JSON format and deserialize it.
        let routeData = Fixture.JSONFromFileNamed(name: "route-for-navigation-camera")
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = routeOptions
        
        guard let route = try? decoder.decode(Route.self, from: routeData) else {
            XCTFail("Route should be valid.")
            return
        }
        
        let routeProgress = RouteProgress(route: route,
                                          routeIndex: 0,
                                          options: routeOptions)
        
        let location = CLLocation(latitude: 37.765469, longitude: -122.415279)
        
        // Since second `stepIndex` is right after sharp maneuver default navigation camera behavior
        // will change `CameraOptions.pitch` to `FollowingCameraOptions.defaultPitch`.
        routeProgress.currentLegProgress.stepIndex = 1
        
        let userInfo: [RouteController.NotificationUserInfoKey: Any] = [
            .routeProgressKey: routeProgress,
            .locationKey: location,
        ]
        
        let expectation = self.expectation(forNotification: .routeControllerProgressDidChange,
                                           object: self) { _ in
            return true
        }
        
        NotificationCenter.default.post(name: .routeControllerProgressDidChange,
                                        object: self,
                                        userInfo: userInfo)
        
        wait(for: [expectation], timeout: 1.0)
        
        guard let temporaryPitch = viewportDataSourceDelegateMock.cameraOptions?[CameraOptions.followingMobileCamera]?.pitch else {
            XCTFail("Pitch should be valid.")
            return
        }
        
        let pitch = Double(temporaryPitch)
        XCTAssertEqual(pitch,
                       navigationViewportDataSource.options.followingCameraOptions.defaultPitch,
                       "Pitches should be equal.")
    }
}
