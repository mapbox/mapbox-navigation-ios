@testable import MapboxNavigationCore
@testable import MapboxNavigationUIKit
@testable import TestHelper
import XCTest

final class CarPlayFreeDriveConfigurationTests: TestCase {
    @MainActor
    func testSceneConnectionDoesNotStartFreeDriveWhenAutomaticStartIsDisabled() {
        var mauEventCount = 0
        billingServiceMock.onTriggerBillingEvent = { _ in mauEventCount += 1 }

        let carPlayManager = CarPlayManager(navigationProvider: navigationProvider)
        carPlayManager.startFreeDriveAutomatically = false

        simulateCarPlayConnection(carPlayManager)
        defer { simulateCarPlayDisconnection(carPlayManager) }

        let mapViewController = carPlayManager.carPlayMapViewController
        XCTAssertNotNil(mapViewController)
        mapViewController?.loadViewIfNeeded()
        XCTAssertEqual(navigationProvider.mapboxNavigation.tripSession().currentSession.state, .idle)
        XCTAssertEqual(mauEventCount, 0)
        billingServiceMock.assertEvents([])
    }

    @MainActor
    func testDirectMapViewControllerCanDisableAutomaticFreeDriveBeforeViewLoading() {
        var mauEventCount = 0
        billingServiceMock.onTriggerBillingEvent = { _ in mauEventCount += 1 }

        let mapViewController = CarPlayMapViewController(
            core: navigationProvider.mapboxNavigation,
            styles: [StandardDayStyle(), StandardNightStyle()]
        )

        XCTAssertFalse(mapViewController.isViewLoaded)
        mapViewController.startFreeDriveAutomatically = false
        mapViewController.loadViewIfNeeded()

        XCTAssertEqual(navigationProvider.mapboxNavigation.tripSession().currentSession.state, .idle)
        XCTAssertEqual(mauEventCount, 0)
        billingServiceMock.assertEvents([])
    }

    @MainActor
    func testSceneConnectionStartsFreeDriveOnceByDefault() {
        var mauEventCount = 0
        billingServiceMock.onTriggerBillingEvent = { _ in mauEventCount += 1 }

        let carPlayManager = CarPlayManager(navigationProvider: navigationProvider)

        simulateCarPlayConnection(carPlayManager)
        defer { simulateCarPlayDisconnection(carPlayManager) }
        carPlayManager.carPlayMapViewController?.loadViewIfNeeded()

        XCTAssertEqual(
            navigationProvider.mapboxNavigation.tripSession().currentSession.state,
            .freeDrive(.active)
        )
        XCTAssertEqual(mauEventCount, 1)
        billingServiceMock.assertEvents([.beginBillingSession(.freeDrive)])
    }
}
