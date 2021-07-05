import Foundation
import XCTest
import CoreLocation
import TestHelper
import MapboxNavigationNative
@testable import MapboxCoreNavigation

final class BillingServiceMock: BillingService {
    var onBeginBillingSession: ((_ sessionType: BillingHandler.SessionType,
                                 _ callback: @escaping (Error) -> Void) -> Void)?
    var onGetSKUTokenIfValid: (() -> String)?
    var onStopBillingSession: (() -> Void)?
    var onTriggerBillingEvent: ((_ onError: @escaping (Error) -> Void) -> Void)?
    var onPauseBillingSession: (() -> Void)?
    var onResumeBillingSession: ((_ onError: @escaping (Error) -> Void) -> Void)?

    func getSKUTokenIfValid() -> String {
        onGetSKUTokenIfValid?() ?? ""
    }

    func stopBillingSession() {
        onStopBillingSession?()
    }

    func triggerBillingEvent(onError: @escaping (Error) -> Void) {
        onTriggerBillingEvent?(onError)
    }

    func beginBillingSession(sessionType: BillingHandler.SessionType, onError: @escaping (Error) -> Void) {
        onBeginBillingSession?(sessionType, onError)
    }

    func pauseBillingSession() {
        onPauseBillingSession?()
    }

    func resumeBillingSession(onError: @escaping (Error) -> Void) {
        onResumeBillingSession?(onError)
    }
}

final class BillingHandlerUnitTests: XCTestCase {
    private enum AnError: Error {
        case any
    }

    private var billingService: BillingServiceMock!
    private var handler: BillingHandler!

    override func setUp() {
        super.setUp()
        billingService = .init()
        handler = BillingHandler(service: billingService)
    }

    override func tearDown() {
        super.tearDown()
        billingService = nil
        handler = nil
    }

    func testSessionStop() {
        let cancelSessionCalled = expectation(description: "Cancel session called")
        let billingEventTriggered = expectation(description: "Billing event triggered")
        billingService.onTriggerBillingEvent = { _ in
            billingEventTriggered.fulfill()
        }
        billingService.onStopBillingSession = {
            cancelSessionCalled.fulfill()
        }

        XCTAssertEqual(handler.sessionState, .stopped)

        handler.beginBillingSession(type: .activeGuidance)

        DispatchQueue.main.async() { [unowned self] in
            handler.stopBillingSession()
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(handler.sessionState, .stopped)
    }

    func testSessionStart() {
        let expectedSessionType = BillingHandler.SessionType.activeGuidance
        let billingEventTriggered = expectation(description: "Billing event triggered")
        let beginSessionTriggered = expectation(description: "Beging session triggered")
        billingService.onStopBillingSession = {
            XCTFail("Cancel shouldn't be called")
        }
        billingService.onBeginBillingSession = { sessionType, _ in
            beginSessionTriggered.fulfill()
            XCTAssertEqual(sessionType, expectedSessionType)
        }

        billingService.onTriggerBillingEvent = { _ in
            billingEventTriggered.fulfill()
        }

        handler.beginBillingSession(type: expectedSessionType)
        XCTAssertEqual(handler.sessionState, .running)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testSessionPause() {
        let sessionStarted = expectation(description: "Session started")
        let sessionPaused = expectation(description: "Session paused")
        billingService.onBeginBillingSession = { _, _ in
            sessionStarted.fulfill()
        }
        billingService.onPauseBillingSession = {
            sessionPaused.fulfill()
        }

        handler.beginBillingSession(type: .freeDrive)
        handler.pauseBillingSession()
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(handler.sessionState, .paused)
        let billingSessionResumed = expectation(description: "Billing session resumed")
        billingService.onResumeBillingSession = { _ in
            billingSessionResumed.fulfill()
        }

        handler.resumeBillingSession()
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(handler.sessionState, .running)
    }

    func testSessionResumeFailed() {
        let expectedSessionType = BillingHandler.SessionType.activeGuidance
        let sessionStarted = expectation(description: "Session started")
        sessionStarted.expectedFulfillmentCount = 2
        billingService.onBeginBillingSession = { sessionType, _ in
            sessionStarted.fulfill()
            XCTAssertEqual(sessionType, expectedSessionType)
        }
        billingService.onResumeBillingSession = { onError in
            DispatchQueue.global().async {
                onError(AnError.any)
            }
        }
        handler.beginBillingSession(type: expectedSessionType)
        handler.pauseBillingSession()
        handler.resumeBillingSession()
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(handler.sessionState, .running)
    }

    func testSessionBeginFailed() {
        let sessionFailed = expectation(description: "Session Failed")
        billingService.onBeginBillingSession = { _, onError in
            DispatchQueue.global().async {
                onError(AnError.any)
                sessionFailed.fulfill()
            }
        }
        handler.beginBillingSession(type: .activeGuidance)
        XCTAssertEqual(handler.sessionState, .running)
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(handler.sessionState, .stopped)
    }

    func testFailedMauBillingDoNotStopSession() {
        let billingEventTriggered = expectation(description: "Billing event triggered")
        billingService.onTriggerBillingEvent = { onError in
            DispatchQueue.global().async {
                onError(AnError.any)
                billingEventTriggered.fulfill()
            }
        }
        handler.beginBillingSession(type: .activeGuidance)
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(handler.sessionState, .running)
    }

    /// If two sessions starts, one after another, and then the first one stopped, the billing session should continue.
    func testTwoSessionsWithOneStopped() {
        let billingSessionStarted = expectation(description: "Billing session started")
        billingSessionStarted.expectedFulfillmentCount = 2
        billingService.onBeginBillingSession = { _, _ in
            billingSessionStarted.fulfill()
        }
        billingService.onStopBillingSession = {
            XCTFail("Shouldn't stop")
        }
        let queue = DispatchQueue(label: "")
        queue.async {
            self.handler.beginBillingSession(type: .freeDrive)
        }
        queue.async {
            self.handler.beginBillingSession(type: .activeGuidance)
            queue.async {
                self.handler.stopBillingSession()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
        RunLoop.main.run(until: Date().addingTimeInterval(1)) // Make sure stop isn't called
    }

    func testTwoSessionsWithResumeFailed() {
        let sessionStarted = expectation(description: "Session started")
        let sessionStopped = expectation(description: "Session stopped")
        sessionStarted.expectedFulfillmentCount = 3
        billingService.onBeginBillingSession = { _, onError in
            sessionStarted.fulfill()
        }
        billingService.onStopBillingSession = {
            sessionStopped.fulfill()
        }
        billingService.onResumeBillingSession = { onError in
            DispatchQueue.global().async {
                onError(AnError.any)
            }
        }
        let queue = DispatchQueue(label: "")
        queue.async {
            self.handler.beginBillingSession(type: .freeDrive)
        }
        queue.async {
            self.handler.beginBillingSession(type: .activeGuidance)
        }
        queue.async {
            self.handler.pauseBillingSession()
        }
        queue.async {
            self.handler.resumeBillingSession()
        }
        queue.async {
            self.handler.stopBillingSession()
        }
        queue.async {
            self.handler.stopBillingSession()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testPausedRouteControllerDoNotUpdateStatus() {
        class DummyRouterDatesource: RouterDataSource {
            var locationProvider: NavigationLocationManager.Type {
                NavigationLocationManager.self
            }
        }
        class RouterDelegateSpy: RouterDelegate {
            var onProgressUpdate: (() -> Void)?

            func router(_ router: MapboxCoreNavigation.Router, didRefresh routeProgress: RouteProgress) {}

            func router(_ router: MapboxCoreNavigation.Router,
                        didUpdate progress: RouteProgress,
                        with location: CLLocation, rawLocation: CLLocation) {
                onProgressUpdate?()
            }
        }

        let routerDateSource = DummyRouterDatesource()
        let routerDelegate = RouterDelegateSpy()
        routerDelegate.onProgressUpdate = {
            XCTFail("Updated on paused session isn't allowed")
        }

        let coordinates:[CLLocationCoordinate2D] = [
            .init(latitude: 59.337928, longitude: 18.076841),
        ]
        let options = NavigationMatchOptions(coordinates: coordinates)
        let route = Fixture.routesFromMatches(at: "sthlm-double-back", options: options)![0]
        let equivalentRouteOptions = NavigationRouteOptions(navigationMatchOptions: options)
        let routeController = RouteController(along: route,
                                              routeIndex: 0,
                                              options: equivalentRouteOptions,
                                              directions: DirectionsSpy(),
                                              dataSource: routerDateSource)
        let locations = Array<CLLocation>.locations(from: "sthlm-double-back-replay")
        let locationManager = ReplayLocationManager(locations: locations)
        locationManager.startDate = Date()
        locationManager.delegate = routeController
        routeController.delegate = routerDelegate
        routeController.pauseDriveSession()
        locationManager.tick()

        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }

    func testPausedPassiveLocationManagerDoNotUpdateStatus() {
        class UpdatesSpy: PassiveLocationManagerDelegate {
            var onProgressUpdate: (() -> Void)?


            func passiveLocationManager(_ manager: PassiveLocationManager,
                                        didUpdateLocation location: CLLocation,
                                        rawLocation: CLLocation) {
                onProgressUpdate?()
            }

            func passiveLocationManagerDidChangeAuthorization(_ manager: PassiveLocationManager) {}
            func passiveLocationManager(_ manager: PassiveLocationManager, didUpdateHeading newHeading: CLHeading) {}
            func passiveLocationManager(_ manager: PassiveLocationManager, didFailWithError error: Error) {}
        }

        let updatesSpy = UpdatesSpy()
        updatesSpy.onProgressUpdate = {
            XCTFail("Updated on paused session isn't allowed")
        }

        let locations = Array<CLLocation>.locations(from: "sthlm-double-back-replay")
        let locationManager = ReplayLocationManager(locations: locations)
        locationManager.startDate = Date()

        let passiveLocationManager = PassiveLocationManager(directions: DirectionsSpy(),
                                                            systemLocationManager: locationManager,
                                                            tileStoreLocation: .default)

        locationManager.delegate = passiveLocationManager
        passiveLocationManager.delegate = updatesSpy
        passiveLocationManager.pauseDriveSession()
        locationManager.tick()

        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }
}
