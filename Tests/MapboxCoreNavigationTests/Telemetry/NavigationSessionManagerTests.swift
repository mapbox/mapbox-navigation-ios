@testable @_spi(MapboxInternal) import MapboxCoreNavigation
@testable import TestHelper
import XCTest

final class NavigationSessionManagerTests: TestCase {
    private var manager: NavigationSessionManager!
    private var coreNavigator: CoreNavigatorSpy!
    private var navigator: NativeNavigatorSpy!

    override func setUp() {
        super.setUp()

        coreNavigator = CoreNavigatorSpy.shared
        navigator = coreNavigator.navigatorSpy
        manager = NavigationSessionManagerImp(navigatorType: CoreNavigatorSpy.self)
        NavigationTelemetryConfiguration.useNavNativeTelemetryEvents = true
    }

    override func tearDown() {
        NavigationTelemetryConfiguration.useNavNativeTelemetryEvents = false
        super.tearDown()
    }

    func testDoNotStartAndStopIfNonNativeTelemetry() {
        NavigationTelemetryConfiguration.useNavNativeTelemetryEvents = false
        manager.reportStopNavigation()
        manager.reportStartNavigation()
        XCTAssertFalse(navigator.startNavigationSessionCalled)
        XCTAssertFalse(navigator.stopNavigationSessionCalled)
    }

    func testStopSessionIfNotStartedIfNativeTelemetry() {
        manager.reportStopNavigation()
        XCTAssertFalse(navigator.stopNavigationSessionCalled, "Should not report stop if not started")

        manager.reportStartNavigation()
        XCTAssertTrue(navigator.startNavigationSessionCalled)
        manager.reportStopNavigation()
        XCTAssertTrue(navigator.stopNavigationSessionCalled)
    }

    func testStartAndStopSessionIfTwoSessionStartedIfNativeTelemetry() {
        manager.reportStartNavigation()
        XCTAssertTrue(navigator.startNavigationSessionCalled, "Should report start if not started")

        navigator.startNavigationSessionCalled = false
        manager.reportStartNavigation()
        XCTAssertFalse(navigator.startNavigationSessionCalled, "Should not report start if already started")

        manager.reportStopNavigation()
        XCTAssertFalse(navigator.stopNavigationSessionCalled, "Should not report stop if more session running")

        manager.reportStopNavigation()
        XCTAssertTrue(navigator.stopNavigationSessionCalled, "Should report stop if no more session running")
    }
}
