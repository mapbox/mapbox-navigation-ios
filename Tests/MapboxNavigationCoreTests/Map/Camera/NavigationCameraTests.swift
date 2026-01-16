import _MapboxNavigationTestHelpers
import Combine
import MapboxDirections
import MapboxMaps
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private
import Turf
import XCTest

class ViewportDataSourceMock: ViewportDataSource {
    var passedViewportState: MapboxNavigationCore.ViewportState?
    var options: NavigationViewportDataSourceOptions = .init()

    var navigationCameraOptions: AnyPublisher<MapboxNavigationCore.NavigationCameraOptions, Never> {
        _navigationCameraOptions.eraseToAnyPublisher()
    }

    var _navigationCameraOptions: CurrentValueSubject<NavigationCameraOptions, Never> = .init(.init())

    var currentNavigationCameraOptions: NavigationCameraOptions {
        get {
            _navigationCameraOptions.value
        }

        set {
            _navigationCameraOptions.value = newValue
        }
    }

    func update(using viewportState: MapboxNavigationCore.ViewportState) {
        passedViewportState = viewportState
    }
}

class CameraStateTransitionMock: CameraStateTransition {
    weak var mapView: MapView?
    var transitionExpectation: XCTestExpectation?
    var updateExpectation: XCTestExpectation?

    var passedUpdateCameraOptions: CameraOptions?

    required init(_ mapView: MapView) {
        self.mapView = mapView
    }

    func transitionTo(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void)) {
        transitionExpectation?.fulfill()
        completion()
    }

    func update(to cameraOptions: CameraOptions, state: NavigationCameraState) {
        passedUpdateCameraOptions = cameraOptions
        updateExpectation?.fulfill()
    }

    func cancelPendingTransition() {
        // No-op
    }
}

class NavigationCameraTests: BaseTestCase {
    var navigationCamera: NavigationCamera!
    var navigationMapView: NavigationMapView!
    var navigationCameraStateTransition: NavigationCameraStateTransition!

    var locationPublisher: CurrentValueSubject<CLLocation, Never>!
    var routeProgressPublisher: CurrentValueSubject<RouteProgress?, Never>!
    var subscriptions: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()

        subscriptions = []
        let location = CLLocation(latitude: 9.519172, longitude: 47.210823)
        locationPublisher = .init(location)
        routeProgressPublisher = .init(nil)

        navigationMapView = await .init(
            location: locationPublisher.eraseToAnyPublisher(),
            routeProgress: routeProgressPublisher.eraseToAnyPublisher()
        )
        navigationCamera = await navigationMapView.navigationCamera
        navigationCameraStateTransition = await NavigationCameraStateTransition(navigationMapView.mapView)
    }

    @MainActor
    func testNavigationMapInitialFollowingStateWithInitialLocation() async {
        navigationMapView = .init(
            location: locationPublisher.eraseToAnyPublisher(),
            routeProgress: routeProgressPublisher.eraseToAnyPublisher()
        )
        // Testing the default navigation map
        if navigationCamera.currentCameraState == .idle {
            let followingCameraExpectation = XCTestExpectation(description: "Camera options expectation.")
            navigationCamera.cameraStates
                .sink { state in
                    XCTAssertEqual(state, .following)
                    followingCameraExpectation.fulfill()
                }.store(in: &subscriptions)
            await fulfillment(of: [followingCameraExpectation], timeout: 1)
            XCTAssertEqual(navigationCamera.currentCameraState, .following)
        } else {
            XCTAssertEqual(navigationCamera.currentCameraState, .following)
        }
    }

    @MainActor
    func testNavigationCameraInitialFollowingState() async {
        let viewportDataSourceMock = ViewportDataSourceMock()
        navigationCamera = NavigationCamera(
            navigationMapView.mapView,
            location: locationPublisher.eraseToAnyPublisher(),
            routeProgress: routeProgressPublisher.eraseToAnyPublisher(),
            viewportDataSource: viewportDataSourceMock
        )
        XCTAssertEqual(navigationCamera.currentCameraState, .idle)

        let followingCameraExpectation = XCTestExpectation(description: "Camera options expectation.")
        navigationCamera.cameraStates
            .sink { state in
                XCTAssertEqual(state, .following)
                followingCameraExpectation.fulfill()
            }.store(in: &subscriptions)
        navigationCamera.update(cameraState: .following)

        let cameraOptions = NavigationCameraOptions(followingCamera: .init(zoom: 10.0))
        viewportDataSourceMock._navigationCameraOptions.send(cameraOptions)

        // Navigation Camera moves to `NavigationCameraState.following` after location update.
        let location = CLLocation(latitude: 37.765469, longitude: -122.415279)
        locationPublisher.send(location)

        await fulfillment(of: [followingCameraExpectation], timeout: 1)
        XCTAssertEqual(navigationCamera.currentCameraState, .following)
    }

    @MainActor
    func testCancelInitialSwitingToFollowingState() async {
        let idleCameraExpectation = XCTestExpectation(description: "Camera options expectation.")
        navigationCamera.cameraStates
            .sink { state in
                XCTAssertEqual(state, .idle)
                idleCameraExpectation.fulfill()
            }.store(in: &subscriptions)

        navigationCamera.stop()
        let viewportDataSourceMock = ViewportDataSourceMock()
        navigationCamera.viewportDataSource = viewportDataSourceMock
        let cameraOptions = NavigationCameraOptions(followingCamera: .init(zoom: 10.0))
        viewportDataSourceMock._navigationCameraOptions.send(cameraOptions)
        navigationCamera.stop()
        // Navigation Camera does not move to the following state if it was cancelled.
        let location = CLLocation(latitude: 37.765469, longitude: -122.415279)
        locationPublisher.send(location)

        await fulfillment(of: [idleCameraExpectation], timeout: 3)
        XCTAssertEqual(navigationCamera.currentCameraState, .idle)
    }

    @MainActor
    func testCameraStateChangeToOverview() async {
        navigationMapView.navigationCamera.update(cameraState: .overview)
        XCTAssertEqual(navigationCamera.currentCameraState, .overview)
    }

    @MainActor
    func testCameraStateChangeToOverviewInActiveGuidance() async {
        let progress = await RouteProgress.mock()
        routeProgressPublisher.send(progress)
        navigationMapView.navigationCamera.update(cameraState: .overview)
        XCTAssertEqual(navigationCamera.currentCameraState, .overview)
    }

    @MainActor
    func testCameraDoesNotChangeAutomaticallyToFollowingIfSwitchedToOverview() async {
        let mock = CameraStateTransitionMock(navigationMapView.mapView)
        navigationCamera.cameraStateTransition = mock
        navigationMapView.navigationCamera.update(cameraState: .overview)

        let expectation = expectation(description: "No transition expectation.")
        expectation.isInverted = true
        mock.transitionExpectation = expectation
        let location = CLLocation(latitude: 37.765469, longitude: -122.415279)
        await waitForLocationUpdate(location)

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(navigationCamera.currentCameraState, .overview)
    }

    @MainActor
    func testNavigationCameraOverviewStateDoesntChangeSecondTime() async {
        let mock = CameraStateTransitionMock(navigationMapView.mapView)
        navigationCamera.cameraStateTransition = mock
        let location = CLLocation(latitude: 37.765469, longitude: -122.415279)
        await waitForLocationUpdate(location)

        let overviewExpectation = expectation(description: "Overview camera expectation.")
        mock.transitionExpectation = overviewExpectation
        await waitForLocationUpdate(location)

        navigationMapView.navigationCamera.update(cameraState: .overview)

        await fulfillment(of: [overviewExpectation], timeout: 1.0)

        // At the end of transition it is expected that camera state is `NavigationCameraState.overview`.
        XCTAssertEqual(navigationCamera.currentCameraState, .overview)

        let overviewNotChangedExpectation = expectation(description: "Overview camera expectation.")
        overviewNotChangedExpectation.isInverted = true
        mock.transitionExpectation = overviewNotChangedExpectation

        navigationMapView.navigationCamera.update(cameraState: .overview)

        await fulfillment(of: [overviewNotChangedExpectation], timeout: 1.0)
        XCTAssertEqual(navigationCamera.currentCameraState, .overview)
    }

    @MainActor
    func testCustomTransition() async {
        let cameraStateTransitionMock = CameraStateTransitionMock(navigationMapView.mapView)
        navigationCamera = NavigationCamera(
            navigationMapView.mapView,
            location: locationPublisher.eraseToAnyPublisher(),
            routeProgress: routeProgressPublisher.eraseToAnyPublisher(),
            cameraStateTransition: cameraStateTransitionMock
        )
        XCTAssertEqual(navigationCamera.currentCameraState, .idle)
        XCTAssertTrue(
            navigationCamera.cameraStateTransition is CameraStateTransitionMock,
            "cameraStateTransition should have correct type."
        )
        let expectation = XCTestExpectation(description: "Custom transition expectation.")
        cameraStateTransitionMock.transitionExpectation = expectation

        navigationCamera.update(cameraState: .following)
        let location = CLLocation(latitude: 37.765469, longitude: -122.415279)
        locationPublisher.send(location)

        await fulfillment(of: [expectation], timeout: 1)

        XCTAssertEqual(navigationCamera.currentCameraState, .following)
    }

    @MainActor
    func testCustomViewportDataSource() async {
        let viewportDataSourceMock = ViewportDataSourceMock()
        let cameraStateTransitionMock = CameraStateTransitionMock(navigationMapView.mapView)

        navigationCamera = NavigationCamera(
            navigationMapView.mapView,
            location: locationPublisher.eraseToAnyPublisher(),
            routeProgress: routeProgressPublisher.eraseToAnyPublisher(),
            viewportDataSource: viewportDataSourceMock,
            cameraStateTransition: cameraStateTransitionMock
        )
        XCTAssertTrue(
            navigationCamera.viewportDataSource is ViewportDataSourceMock,
            "viewportDataSource should have correct type."
        )

        let transitionExpectation = XCTestExpectation(description: "Custom transition expectation.")
        cameraStateTransitionMock.transitionExpectation = transitionExpectation
        let followingCameraExpectation = XCTestExpectation(description: "Camera options expectation.")
        navigationCamera.cameraStates
            .sink { state in
                XCTAssertEqual(state, .following)
                followingCameraExpectation.fulfill()
            }.store(in: &subscriptions)

        navigationCamera.update(cameraState: .following)
        let cameraCoordinate = CLLocationCoordinate2D(latitude: 37.765469, longitude: -122.415279)
        viewportDataSourceMock._navigationCameraOptions.send(.init(
            followingCamera: .init(center: cameraCoordinate)
        ))
        locationPublisher.send(.init(coordinate: cameraCoordinate))
        await fulfillment(of: [transitionExpectation, followingCameraExpectation], timeout: 1)

        let coordinate = CLLocationCoordinate2D(latitude: 37.788443, longitude: -122.4020258)
        let cameraOptions = CameraOptions(
            center: coordinate,
            padding: .zero,
            anchor: .zero,
            zoom: 15.0,
            bearing: 0.0,
            pitch: 45.0
        )
        let expectation = XCTestExpectation(description: "Custom viewport expectation.")
        cameraStateTransitionMock.updateExpectation = expectation
        let navigationCameraOptions = NavigationCameraOptions(followingCamera: cameraOptions)
        viewportDataSourceMock._navigationCameraOptions.send(navigationCameraOptions)
        await fulfillment(of: [expectation], timeout: 1)

        XCTAssertEqual(cameraStateTransitionMock.passedUpdateCameraOptions, cameraOptions)
    }

    @MainActor
    func testCustomViewportDataSourceWithEmptyCameraOptions() async {
        let viewportDataSourceMock = ViewportDataSourceMock()
        let cameraStateTransitionMock = CameraStateTransitionMock(navigationMapView.mapView)

        navigationCamera.viewportDataSource = viewportDataSourceMock
        navigationCamera.cameraStateTransition = cameraStateTransitionMock

        let transitionExpectation = XCTestExpectation(description: "Custom transition expectation.")
        transitionExpectation.isInverted = true
        cameraStateTransitionMock.transitionExpectation = transitionExpectation

        let location = CLLocation(latitude: 37.765469, longitude: -122.415279)
        locationPublisher.send(location)

        await fulfillment(of: [transitionExpectation], timeout: 1)
    }

    @MainActor
    func testNavigationCameraIdleState() async {
        // Navigation Camera moves to `NavigationCameraState.following` after location update.
        let location = CLLocation(latitude: 37.765469, longitude: -122.415279)
        await waitForLocationUpdate(location)

        XCTAssertEqual(navigationCamera.currentCameraState, .following)

        // After calling `NavigationCamera.stop()` camera state should be set to
        // `NavigationCameraState.idle`.
        navigationMapView.navigationCamera.stop()
        XCTAssertEqual(navigationMapView.navigationCamera.currentCameraState, .idle)

        // All further calls to `NavigationCamera.stop()` should not change camera state.
        navigationMapView.navigationCamera.stop()
        XCTAssertEqual(navigationCamera.currentCameraState, .idle)
    }

    @MainActor
    func testViewportDataSourceForMobileFreeDrive() async {
        let navigationViewportDataSource = navigationCamera.viewportDataSource as? MobileViewportDataSource
        let location = CLLocation(latitude: 37.765469, longitude: -122.415279)
        await waitForLocationUpdate(location)

        // It is expected that `NavigationViewportDataSource` uses default values for `CameraOptions`
        // during free-drive. Location, snapped to the road network should be used instead of raw one.
        let expectedAltitude = 1700.0
        let expectedZoomLevel = CGFloat(ZoomLevelForAltitude(
            expectedAltitude,
            navigationMapView.mapView.mapboxMap.cameraState.pitch,
            location.coordinate.latitude,
            navigationMapView.mapView.bounds.size
        ))

        let mapView = navigationMapView.mapView
        let expectedCameraOptions = CameraOptions(
            center: location.coordinate,
            padding: mapView.safeAreaInsets,
            anchor: mapView.center,
            zoom: expectedZoomLevel,
            bearing: location.course,
            pitch: 0.0
        )

        let cameraOptions = navigationViewportDataSource?.currentNavigationCameraOptions
        let followingMobileCameraOptions = cameraOptions?.followingCamera
        verifyCameraOptionsAreEqual(followingMobileCameraOptions, expectedCameraOptions: expectedCameraOptions)

        // In `NavigationCameraState.overview` state during free-drive navigation all properties of
        // `CameraOptions` should be `nil`.
        let overviewMobileCameraOptions = cameraOptions?.overviewCamera
        verifyCameraOptionsAreNil(overviewMobileCameraOptions)
    }

    @MainActor
    func testViewportDataSourceForActiveGuidance() async throws {
        let navigationViewportDataSource = navigationCamera.viewportDataSource as? MobileViewportDataSource
        let location = CLLocation(latitude: 37.112341, longitude: -122.1111678)
        await waitForLocationUpdate(location)

        var progress = await RouteProgress.mock()
        let status = NavigationStatus.mock(stepIndex: 1)
        progress.update(using: status)
        routeProgressPublisher.send(progress)

        try await Task.sleep(nanoseconds: NSEC_PER_SEC)

        let cameraOptions = navigationViewportDataSource?.currentNavigationCameraOptions
        guard let temporaryPitch = cameraOptions?.followingCamera.pitch else {
            XCTFail("Pitch should be valid.")
            return
        }

        let pitch = Double(temporaryPitch)
        XCTAssertEqual(
            pitch,
            navigationViewportDataSource?.options.followingCameraOptions.defaultPitch,
            "Pitches should be equal."
        )
    }

    @MainActor
    func testViewportDataSourceForLocation() async {
        let navigationViewportDataSource = navigationCamera.viewportDataSource as? MobileViewportDataSource

        // Navigation Camera moves to `NavigationCameraState.following` after location update.
        let location = CLLocation(latitude: 0.0, longitude: 0.0)
        await waitForLocationUpdate(location)

        // It is expected that `NavigationViewportDataSource` uses default values for `CameraOptions`
        // in case if raw locations are consumed.
        let expectedAltitude = 1700.0
        let mapView = navigationMapView.mapView
        let expectedZoomLevel = CGFloat(ZoomLevelForAltitude(
            expectedAltitude,
            mapView.mapboxMap.cameraState.pitch,
            location.coordinate.latitude,
            mapView.bounds.size
        ))
        let expectedCameraOptions = CameraOptions(
            center: location.coordinate,
            padding: mapView.safeAreaInsets,
            anchor: mapView.center,
            zoom: expectedZoomLevel,
            bearing: location.course,
            pitch: 0.0
        )
        let cameraOptions = navigationViewportDataSource?.currentNavigationCameraOptions
        verifyCameraOptionsAreEqual(cameraOptions?.followingCamera, expectedCameraOptions: expectedCameraOptions)
    }

    @MainActor
    func testFollowingCameraOptions() async {
        let navigationViewportDataSource = MobileViewportDataSource(navigationMapView.mapView)

        // Prevent any camera related modifications, which could be done by `NavigationViewportDataSource`.
        navigationViewportDataSource.options.followingCameraOptions.centerUpdatesAllowed = false
        navigationViewportDataSource.options.followingCameraOptions.zoomUpdatesAllowed = false
        navigationViewportDataSource.options.followingCameraOptions.bearingUpdatesAllowed = false
        navigationViewportDataSource.options.followingCameraOptions.pitchUpdatesAllowed = false
        navigationViewportDataSource.options.followingCameraOptions.paddingUpdatesAllowed = false

        let expectedCenterCoordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        navigationViewportDataSource.currentNavigationCameraOptions.followingCamera.center = expectedCenterCoordinate

        let expectedZoom: CGFloat = 11.1
        navigationViewportDataSource.currentNavigationCameraOptions.followingCamera.zoom = expectedZoom

        let expectedBearing = 22.2
        navigationViewportDataSource.currentNavigationCameraOptions.followingCamera.bearing = expectedBearing

        let expectedPitch: CGFloat = 33.3
        navigationViewportDataSource.currentNavigationCameraOptions.followingCamera.pitch = expectedPitch

        let expectedPadding = UIEdgeInsets(top: 1.0, left: 2.0, bottom: 3.0, right: 4.0)
        navigationViewportDataSource.currentNavigationCameraOptions.followingCamera.padding = expectedPadding

        navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource

        navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
        let expectation = XCTestExpectation(description: "Camera options expectation.")
        var options: NavigationCameraOptions?
        navigationViewportDataSource.navigationCameraOptions
            .dropFirst()
            .sink { navigationCameraOptions in
                options = navigationCameraOptions
                expectation.fulfill()
            }.store(in: &subscriptions)

        let location = CLLocation(latitude: 37.765469, longitude: -122.415279)
        locationPublisher.send(location)
        var progress = await RouteProgress.mock()
        let status = NavigationStatus.mock(stepIndex: 1)
        progress.update(using: status)
        routeProgressPublisher.send(progress)

        await fulfillment(of: [expectation], timeout: 1)

        let cameraOptions = options?.followingCamera
        XCTAssertEqual(cameraOptions?.center, expectedCenterCoordinate, "Center coordinates should be equal.")
        XCTAssertEqual(cameraOptions?.zoom, expectedZoom, "Zooms should be equal.")
        XCTAssertEqual(cameraOptions?.bearing, expectedBearing, "Bearings should be equal.")
        XCTAssertEqual(cameraOptions?.pitch, expectedPitch, "Pitches should be equal.")
        XCTAssertEqual(cameraOptions?.padding, expectedPadding, "Paddings should be equal.")
    }

    @MainActor
    func testFollowingCameraModificationsDisabled() async {
        // Create new `NavigationViewportDataSource` instance, which listens to the
        // `Notification.Name.routeControllerProgressDidChange` notification, which is sent during
        // active guidance navigation.
        let navigationViewportDataSource = MobileViewportDataSource(navigationMapView.mapView)

        // Some camera related modifications disabled while others not. It is expected that `CameraOptions` should
        // still have non-nil default values after the progress update. Camera related properties with disabled
        // modifications should also keep default value unchanged.
        navigationViewportDataSource.options.followingCameraOptions.centerUpdatesAllowed = true
        navigationViewportDataSource.options.followingCameraOptions.zoomUpdatesAllowed = false
        navigationViewportDataSource.options.followingCameraOptions.bearingUpdatesAllowed = false
        navigationViewportDataSource.options.followingCameraOptions.pitchUpdatesAllowed = true
        navigationViewportDataSource.options.followingCameraOptions.paddingUpdatesAllowed = true

        let expectedZoom: CGFloat = 11.1
        navigationViewportDataSource.currentNavigationCameraOptions.followingCamera.zoom = expectedZoom

        let expectedBearing = 22.2
        navigationViewportDataSource.currentNavigationCameraOptions.followingCamera.bearing = expectedBearing

        navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
        let expectation = XCTestExpectation(description: "Camera options expectation.")
        var options: NavigationCameraOptions?
        navigationViewportDataSource.navigationCameraOptions
            .dropFirst()
            .sink { navigationCameraOptions in
                options = navigationCameraOptions
                expectation.fulfill()
            }.store(in: &subscriptions)

        let location = CLLocation(latitude: 37.765469, longitude: -122.415279)
        locationPublisher.send(location)
        var progress = await RouteProgress.mock()
        let status = NavigationStatus.mock(stepIndex: 1)
        progress.update(using: status)
        routeProgressPublisher.send(progress)

        await fulfillment(of: [expectation], timeout: 1)

        let cameraOptions = options?.followingCamera
        XCTAssertNotNil(cameraOptions?.center, "Center coordinates should be valid.")
        XCTAssertEqual(cameraOptions?.zoom, expectedZoom, "Zooms should be equal.")
        XCTAssertEqual(cameraOptions?.bearing, expectedBearing, "Bearings should be equal.")
        XCTAssertNotNil(cameraOptions?.pitch, "Pitches should be valid.")
        XCTAssertNotNil(cameraOptions?.padding, "Paddings should be valid.")
    }

    @MainActor
    func testBearingSmoothingIsDisabled() async {
        guard let navigationViewportDataSource = navigationCamera.viewportDataSource as? MobileViewportDataSource else {
            XCTFail("Should have mobile viewportDataSource")
            return
        }

        // Make sure that bearing smoothing is enabled by default.
        XCTAssertTrue(
            navigationViewportDataSource.options.followingCameraOptions.bearingSmoothing.enabled,
            "Bearing smoothing should be enabled by default."
        )

        navigationViewportDataSource.options.followingCameraOptions.bearingSmoothing.enabled = false

        navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource

        let expectation = XCTestExpectation(description: "Camera options expectation.")
        var options: NavigationCameraOptions?
        navigationViewportDataSource.navigationCameraOptions
            .dropFirst()
            .sink { navigationCameraOptions in
                options = navigationCameraOptions
                expectation.fulfill()
            }.store(in: &subscriptions)

        // Since bearing smoothing is disabled it is expected that `CameraOptions.bearing`, which was
        // returned from the `ViewportDataSourceDelegateMock` will be `123.0`.
        let expectedBearing = 123.0
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.769595, longitude: -122.442412),
            altitude: 0.0,
            horizontalAccuracy: 0.0,
            verticalAccuracy: 0.0,
            course: expectedBearing,
            speed: 0.0,
            timestamp: Date()
        )
        locationPublisher.send(location)
        let progress = await RouteProgress.mock()
        routeProgressPublisher.send(progress)

        await fulfillment(of: [expectation], timeout: 1)

        let cameraOptions = options?.followingCamera
        XCTAssertEqual(cameraOptions?.bearing, expectedBearing, "Bearings should be equal.")
    }

    @MainActor
    func testRunningAnimators() {
        let window = UIWindow()
        window.addSubview(navigationMapView)

        let cameraOptions = CameraOptions(
            center: CLLocationCoordinate2D(
                latitude: 37.788443,
                longitude: -122.4020258
            ),
            padding: .zero,
            anchor: .zero,
            zoom: 15.0,
            bearing: 0.0,
            pitch: 45.0
        )
        navigationCameraStateTransition.update(to: cameraOptions, state: .overview)

        // Attempt to stop animators right away to verify that no side effects occur.
        navigationCameraStateTransition.cancelPendingTransition()

        // Anchor and padding animators are not created when performing transition to the
        // `NavigationCameraState.following` state.
        guard let animatorCenter = navigationCameraStateTransition.animatorCenter,
              let animatorZoom = navigationCameraStateTransition.animatorZoom,
              let animatorBearing = navigationCameraStateTransition.animatorBearing,
              let animatorPitch = navigationCameraStateTransition.animatorPitch
        else {
            XCTFail("Animators should be available.")
            return
        }

        XCTAssertFalse(animatorCenter.isRunning, "Center animator should not be running.")
        XCTAssertFalse(animatorZoom.isRunning, "Zoom animator should not be running.")
        XCTAssertFalse(animatorBearing.isRunning, "Bearing animator should not be running.")
        XCTAssertFalse(animatorPitch.isRunning, "Pitch animator should not be running.")
    }

    @MainActor
    func testNavigationViewportDataSourceOptionsInitializer() {
        // `NavigationViewportDataSourceOptions` initializers should be available for public usage.
        let navigationViewportDataSourceOptions = NavigationViewportDataSourceOptions()
        let navigationViewportDataSource = navigationCamera.viewportDataSource as? MobileViewportDataSource
        navigationViewportDataSource?.options = navigationViewportDataSourceOptions

        XCTAssertEqual(
            navigationViewportDataSource?.options,
            navigationViewportDataSourceOptions,
            "NavigationViewportDataSourceOptions instances should be equal."
        )

        let followingCameraOptions = FollowingCameraOptions()
        let overviewCameraOptions = OverviewCameraOptions()

        let modifiedNavigationViewportDataSourceOptions = NavigationViewportDataSourceOptions(
            followingCameraOptions: followingCameraOptions,
            overviewCameraOptions: overviewCameraOptions
        )

        XCTAssertEqual(
            modifiedNavigationViewportDataSourceOptions.followingCameraOptions,
            followingCameraOptions,
            "FollowingCameraOptions instances should be equal."
        )

        XCTAssertEqual(
            modifiedNavigationViewportDataSourceOptions.overviewCameraOptions,
            overviewCameraOptions,
            "OverviewCameraOptions instances should be equal."
        )
    }

    @MainActor
    func testInvalidCameraOptions() {
        let invalidCoordinates = [
            CLLocationCoordinate2D(
                latitude: CLLocationDegrees.nan,
                longitude: CLLocationDegrees.nan
            ),
            CLLocationCoordinate2D(
                latitude: Double.greatestFiniteMagnitude,
                longitude: Double.greatestFiniteMagnitude
            ),
            CLLocationCoordinate2D(
                latitude: Double.leastNormalMagnitude,
                longitude: Double.greatestFiniteMagnitude
            ),
        ]

        invalidCoordinates.forEach { invalidCoordinate in
            let cameraOptions = CameraOptions(
                center: invalidCoordinate,
                padding: .zero,
                anchor: .zero,
                zoom: 15.0,
                bearing: 0.0,
                pitch: 45.0
            )

            XCTAssertNoThrow(
                navigationCameraStateTransition.update(to: cameraOptions, state: .overview),
                "Update animation should not be performed for invalid coordinate."
            )

            XCTAssertNoThrow(
                navigationCameraStateTransition.transitionTo(cameraOptions, completion: {}),
                "Transition animation should not be performed for invalid coordinate."
            )
        }
    }

    // MARK: - Helper methods

    @MainActor
    private func waitForLocationUpdate(_ location: CLLocation) async {
        let navigationViewportDataSource = navigationCamera.viewportDataSource
        let cameraExpectation = XCTestExpectation(description: "Camera options expectation.")
        navigationViewportDataSource.navigationCameraOptions
            .filter { $0.followingCamera.center == location.coordinate }
            .sink { _ in cameraExpectation.fulfill() }
            .store(in: &subscriptions)
        locationPublisher.send(location)
        await fulfillment(of: [cameraExpectation], timeout: 1.0)
    }

    private func verifyCameraOptionsAreEqual(
        _ givenCameraOptions: CameraOptions?,
        expectedCameraOptions: CameraOptions?
    ) {
        XCTAssertEqual(givenCameraOptions?.center, expectedCameraOptions?.center, "Center coordinates should be equal.")
        XCTAssertEqual(givenCameraOptions?.anchor, expectedCameraOptions?.anchor, "Anchors should be equal.")
        XCTAssertEqual(givenCameraOptions?.padding, expectedCameraOptions?.padding, "Paddings should be equal.")
        XCTAssertEqual(givenCameraOptions?.bearing, expectedCameraOptions?.bearing, "Bearings should be equal.")
        XCTAssertEqual(givenCameraOptions?.zoom, expectedCameraOptions?.zoom, "Zooms should be equal.")
        XCTAssertEqual(givenCameraOptions?.pitch, expectedCameraOptions?.pitch, "Pitches should be equal.")
    }

    func verifyCameraOptionsAreNil(_ cameraOptions: CameraOptions?) {
        XCTAssertNil(cameraOptions?.center, "Center should be nil.")
        XCTAssertNil(cameraOptions?.anchor, "Anchor should be nil.")
        XCTAssertNil(cameraOptions?.padding, "Padding should be nil.")
        XCTAssertNil(cameraOptions?.bearing, "Bearing should be nil.")
        XCTAssertNil(cameraOptions?.zoom, "Zoom should be nil.")
        XCTAssertNil(cameraOptions?.pitch, "Pitch should be nil.")
    }
}
