import CoreLocation
@testable import MapboxNavigationCore
@testable import MapboxNavigationUIKit
@testable import TestHelper
import XCTest

final class CarPlayFreeDriveConfigurationTests: TestCase {
    @MainActor
    func testSceneConnectionDoesNotStartFreeDriveWhenAutomaticStartIsDisabled() {
        let carPlayManager = CarPlayManager(navigationProvider: navigationProvider)
        carPlayManager.startFreeDriveAutomatically = false

        simulateCarPlayConnection(carPlayManager)
        defer { simulateCarPlayDisconnection(carPlayManager) }

        let mapViewController = carPlayManager.carPlayMapViewController
        XCTAssertNotNil(mapViewController)
        mapViewController?.loadViewIfNeeded()
        XCTAssertEqual(navigationProvider.mapboxNavigation.tripSession().currentSession.state, .idle)
        billingServiceMock.assertAllEvents([])
    }

    @MainActor
    func testDirectMapViewControllerCanDisableAutomaticFreeDriveBeforeViewLoading() {
        let mapViewController = CarPlayMapViewController(
            core: navigationProvider.mapboxNavigation,
            styles: [StandardDayStyle(), StandardNightStyle()]
        )

        XCTAssertFalse(mapViewController.isViewLoaded)
        mapViewController.startFreeDriveAutomatically = false
        mapViewController.loadViewIfNeeded()

        XCTAssertEqual(navigationProvider.mapboxNavigation.tripSession().currentSession.state, .idle)
        billingServiceMock.assertAllEvents([])
    }

    @MainActor
    func testExternallyStartedFreeDriveUpdatesBrowsingOverlaysWhenAutomaticStartIsDisabled() async {
        let mapViewController = CarPlayMapViewController(
            core: navigationProvider.mapboxNavigation,
            styles: [StandardDayStyle(), StandardNightStyle()]
        )
        mapViewController.startFreeDriveAutomatically = false
        mapViewController.loadViewIfNeeded()

        XCTAssertEqual(navigationProvider.mapboxNavigation.tripSession().currentSession.state, .idle)

        navigationProvider.mapboxNavigation.tripSession().startFreeDrive()

        let expectedSpeed: CLLocationSpeed = 15
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 9.519172, longitude: 47.210823),
            altitude: 5,
            horizontalAccuracy: 10,
            verticalAccuracy: 5,
            course: 20,
            speed: expectedSpeed,
            timestamp: Date()
        )
        let status = TestNavigationStatusProvider.createNavigationStatus(location: location)

        await navigationProvider.navigator()._statusProcessor.updateMapMatching(status: status)

        XCTAssertEqual(mapViewController.speedLimitView.currentSpeed, expectedSpeed)
    }

    @MainActor
    func testSettingTripSessionToIdleClearsBrowsingOverlays() throws {
        try assertSessionStateClearsBrowsingOverlays(.idle)
    }

    @MainActor
    func testPausingFreeDriveClearsBrowsingOverlays() throws {
        try assertSessionStateClearsBrowsingOverlays(.freeDrive(.paused))
    }

    @MainActor
    private func assertSessionStateClearsBrowsingOverlays(_ sessionState: Session.State) throws {
        let mapViewController = CarPlayMapViewController(
            core: navigationProvider.mapboxNavigation,
            styles: [StandardDayStyle(), StandardNightStyle()]
        )
        mapViewController.startFreeDriveAutomatically = false
        mapViewController.loadViewIfNeeded()

        let navigator = try XCTUnwrap(navigationProvider.mapboxNavigation.tripSession() as? MapboxNavigator)
        navigator.privateSession.emit(Session(state: .freeDrive(.active)))
        mapViewController.didUpdatePassiveLocation(makeMapMatchingState())

        XCTAssertEqual(mapViewController.speedLimitView.currentSpeed, 15)
        XCTAssertEqual(mapViewController.wayNameView.text, "Test road")
        XCTAssertFalse(mapViewController.wayNameView.containerView.isHidden)

        navigator.privateSession.emit(Session(state: sessionState))

        XCTAssertNil(mapViewController.speedLimitView.speedLimit)
        XCTAssertNil(mapViewController.speedLimitView.currentSpeed)
        XCTAssertNil(mapViewController.wayNameView.text)
        XCTAssertTrue(mapViewController.wayNameView.containerView.isHidden)
    }

    @MainActor
    func testAutomaticStartDoesNotAffectRunningActiveGuidance() throws {
        try assertAutomaticStartLeavesSessionUntouched(.activeGuidance(.uncertain))
    }

    @MainActor
    func testAutomaticStartDoesNotResumePausedFreeDrive() throws {
        try assertAutomaticStartLeavesSessionUntouched(.freeDrive(.paused))
    }

    @MainActor
    private func assertAutomaticStartLeavesSessionUntouched(
        _ sessionState: Session.State,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let navigator = try XCTUnwrap(navigationProvider.mapboxNavigation.tripSession() as? MapboxNavigator)
        navigator.privateSession.emit(Session(state: sessionState))

        let mapViewController = CarPlayMapViewController(
            core: navigationProvider.mapboxNavigation,
            styles: [StandardDayStyle(), StandardNightStyle()]
        )
        XCTAssertTrue(mapViewController.startFreeDriveAutomatically, file: file, line: line)
        mapViewController.loadViewIfNeeded()

        XCTAssertEqual(
            navigationProvider.mapboxNavigation.tripSession().currentSession.state,
            sessionState,
            file: file,
            line: line
        )
        billingServiceMock.assertAllEvents([], file: file, line: line)
    }

    @MainActor
    func testSceneConnectionStartsFreeDriveOnceByDefault() {
        let carPlayManager = CarPlayManager(navigationProvider: navigationProvider)

        simulateCarPlayConnection(carPlayManager)
        defer { simulateCarPlayDisconnection(carPlayManager) }
        carPlayManager.carPlayMapViewController?.loadViewIfNeeded()

        XCTAssertEqual(
            navigationProvider.mapboxNavigation.tripSession().currentSession.state,
            .freeDrive(.active)
        )
        billingServiceMock.assertAllEvents([
            .mau,
            .beginBillingSession(.freeDrive),
        ])
    }
}
