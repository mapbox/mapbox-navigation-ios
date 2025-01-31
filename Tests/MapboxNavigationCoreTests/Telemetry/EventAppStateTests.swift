import _MapboxNavigationTestHelpers
@testable import MapboxNavigationCore
import XCTest

final class EventAppStateTests: TestCase {
    var environment: EventAppState.Environment!
    var screenOrientation: UIDeviceOrientation!
    var deviceOrientation: UIDeviceOrientation!
    var date: Date!
    var applicationState: UIApplication.State!

    var appState: EventAppState!

    override func setUp() async throws {
        try? await super.setUp()

        date = Date()
        applicationState = .active
        screenOrientation = .portrait
        deviceOrientation = .portrait
        environment = EventAppState.Environment(
            date: { self.date },
            applicationState: { self.applicationState },
            screenOrientation: { self.screenOrientation },
            deviceOrientation: { self.deviceOrientation }
        )
        appState = await EventAppState(environment: environment)
    }

    override func tearDown() {
        super.tearDown()
        appState = nil
    }

    @MainActor
    func makeEventAppState() -> EventAppState {
        let environment = EventAppState.Environment(
            date: { self.date },
            applicationState: { self.applicationState },
            screenOrientation: { self.screenOrientation },
            deviceOrientation: { self.deviceOrientation }
        )
        return EventAppState(environment: environment)
    }

    @MainActor
    func testReturnPercentTimeInForegroundIfStartedInBackground() {
        let initialDate = environment.date()
        applicationState = .background
        appState = makeEventAppState()
        XCTAssertEqual(appState.percentTimeInForeground, 100, "Should return 100 if just started")
        date = initialDate.addingTimeInterval(0.001)
        XCTAssertEqual(appState.percentTimeInForeground, 0, "Should return 0 if session started in background state")

        date = initialDate.addingTimeInterval(60)
        XCTAssertEqual(appState.percentTimeInForeground, 0, "Should return 100 after delay")

        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil, userInfo: nil)
        XCTAssertEqual(appState.percentTimeInForeground, 0)

        date = initialDate.addingTimeInterval(120)
        XCTAssertEqual(appState.percentTimeInForeground, 50)
    }

    func testReturnPercentTimeInForeground() {
        let initialDate = environment.date()
        XCTAssertEqual(appState.percentTimeInForeground, 100, "Should return 100 if session started in active state")
        date = initialDate.addingTimeInterval(0.001)
        XCTAssertEqual(appState.percentTimeInForeground, 100, "Should return 100 if session started in active state")

        date = initialDate.addingTimeInterval(60)
        XCTAssertEqual(appState.percentTimeInForeground, 100, "Should return 100 after delay")

        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil, userInfo: nil)
        XCTAssertEqual(appState.percentTimeInForeground, 100)

        date = initialDate.addingTimeInterval(240)
        XCTAssertEqual(appState.percentTimeInForeground, 25)
    }

    func testReturnPercentTimeIfZeroTimePassed() {
        XCTAssertEqual(appState.percentTimeInPortrait, 100)
    }

    @MainActor
    func testReturnPercentTimeInInitialPortrait() {
        let initialDate = environment.date()
        date = initialDate.addingTimeInterval(0.001)
        XCTAssertEqual(appState.percentTimeInPortrait, 100)

        deviceOrientation = .portraitUpsideDown
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil, userInfo: nil)
        date = initialDate.addingTimeInterval(10)
        XCTAssertEqual(appState.percentTimeInPortrait, 100, "Should take portraitUpsideDown as portrait")

        deviceOrientation = .landscapeLeft
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil, userInfo: nil)
        XCTAssertEqual(appState.percentTimeInPortrait, 100)

        date = initialDate.addingTimeInterval(20)
        XCTAssertEqual(appState.percentTimeInPortrait, 50)

        deviceOrientation = .landscapeRight
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil, userInfo: nil)
        date = initialDate.addingTimeInterval(30)
        XCTAssertEqual(appState.percentTimeInPortrait, 33)
    }

    @MainActor
    func testReturnPercentTimeInInitialLandscape() {
        let initialDate = environment.date()
        screenOrientation = .landscapeLeft
        appState = makeEventAppState()
        date = initialDate.addingTimeInterval(0.001)
        XCTAssertEqual(appState.percentTimeInPortrait, 0, "Should return 0 for initial value")

        deviceOrientation = .landscapeRight
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil, userInfo: nil)
        date = initialDate.addingTimeInterval(10)
        XCTAssertEqual(appState.percentTimeInPortrait, 0)

        deviceOrientation = .landscapeLeft
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil, userInfo: nil)
        XCTAssertEqual(appState.percentTimeInPortrait, 0)

        date = initialDate.addingTimeInterval(20)
        XCTAssertEqual(appState.percentTimeInPortrait, 0)

        deviceOrientation = .portrait
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil, userInfo: nil)
        date = initialDate.addingTimeInterval(30)
        XCTAssertEqual(appState.percentTimeInPortrait, 33)

        deviceOrientation = .portraitUpsideDown
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil, userInfo: nil)
        date = initialDate.addingTimeInterval(40)
        XCTAssertEqual(appState.percentTimeInPortrait, 50)

        deviceOrientation = .landscapeRight
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil, userInfo: nil)
        date = initialDate.addingTimeInterval(50)
        XCTAssertEqual(appState.percentTimeInPortrait, 40)
    }

    func testIgnoresFaceUpAndDownChanges() {
        deviceOrientation = .faceUp
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil, userInfo: nil)
        date = date.addingTimeInterval(10)
        XCTAssertEqual(appState.percentTimeInPortrait, 100)

        deviceOrientation = .faceDown
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil, userInfo: nil)
        date = date.addingTimeInterval(10)
        XCTAssertEqual(appState.percentTimeInPortrait, 100)
    }
}
