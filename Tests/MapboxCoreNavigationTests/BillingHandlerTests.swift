import Foundation
import XCTest
import CoreLocation
import TestHelper
import MapboxNavigationNative
@testable import MapboxCoreNavigation

final class BillingHandlerUnitTests: TestCase {
    private var billingService: BillingServiceMock!
    private var handler: BillingHandler!

    override func setUp() {
        super.setUp()
        billingService = .init()
        handler = BillingHandler.__createMockedHandler(with: billingService)
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
        billingService.onStopBillingSession = { _ in
            cancelSessionCalled.fulfill()
        }

        XCTAssertEqual(handler.sessionState, .stopped)

        handler.beginBillingSession(for: .activeGuidance)

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
        billingService.onStopBillingSession = { _ in
            XCTFail("Cancel shouldn't be called")
        }
        billingService.onBeginBillingSession = { sessionType, _ in
            beginSessionTriggered.fulfill()
            XCTAssertEqual(sessionType, expectedSessionType)
        }

        billingService.onTriggerBillingEvent = { _ in
            billingEventTriggered.fulfill()
        }

        handler.beginBillingSession(for: expectedSessionType)
        XCTAssertEqual(handler.sessionState, .running)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testSessionPause() {
        let sessionStarted = expectation(description: "Session started")
        let sessionPaused = expectation(description: "Session paused")
        billingService.onBeginBillingSession = { _, _ in
            sessionStarted.fulfill()
        }
        billingService.onPauseBillingSession = { _ in
            sessionPaused.fulfill()
        }

        handler.beginBillingSession(for: .freeDrive)
        handler.pauseBillingSession()
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(handler.sessionState, .paused)
        let billingSessionResumed = expectation(description: "Billing session resumed")
        billingService.onResumeBillingSession = { _, _ in
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
        billingService.onResumeBillingSession = { _, onError in
            DispatchQueue.global().async {
                onError(.resumeFailed)
            }
        }
        handler.beginBillingSession(for: expectedSessionType)
        handler.pauseBillingSession()
        handler.resumeBillingSession()
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(handler.sessionState, .running)
    }

    func testSessionBeginFailed() {
        let sessionFailed = expectation(description: "Session Failed")
        billingService.onBeginBillingSession = { _, onError in
            DispatchQueue.global().async {
                onError(.tokenValidationFailed)
                sessionFailed.fulfill()
            }
        }
        handler.beginBillingSession(for: .activeGuidance)
        XCTAssertEqual(handler.sessionState, .running)
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(handler.sessionState, .stopped)
    }

    func testFailedMauBillingDoNotStopSession() {
        let billingEventTriggered = expectation(description: "Billing event triggered")
        billingService.onTriggerBillingEvent = { onError in
            DispatchQueue.global().async {
                onError(.tokenValidationFailed)
                billingEventTriggered.fulfill()
            }
        }
        handler.beginBillingSession(for: .activeGuidance)
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
        billingService.onStopBillingSession = { _ in
            XCTFail("Shouldn't stop")
        }
        let queue = DispatchQueue(label: "")
        queue.async {
            self.handler.beginBillingSession(for: .freeDrive)
        }
        queue.async {
            self.handler.beginBillingSession(for: .activeGuidance)
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
        billingService.onStopBillingSession = { _ in
            sessionStopped.fulfill()
        }
        billingService.onResumeBillingSession = { _, onError in
            DispatchQueue.global().async {
                onError(.resumeFailed)
            }
        }
        let queue = DispatchQueue(label: "")
        queue.async {
            self.handler.beginBillingSession(for: .freeDrive)
        }
        queue.async {
            self.handler.beginBillingSession(for: .activeGuidance)
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

    func testTokens() {
        let freeRideToken = UUID().uuidString
        let activeGuidanceToken = UUID().uuidString

        billingService.onGetSKUTokenIfValid = { sessionType in
            switch sessionType {
            case .activeGuidance: return activeGuidanceToken
            case .freeDrive: return freeRideToken
            }
        }

        handler.beginBillingSession(for: .freeDrive)
        XCTAssertEqual(handler.sessionToken, freeRideToken)
        handler.beginBillingSession(for: .activeGuidance)
        XCTAssertEqual(handler.sessionToken, activeGuidanceToken)
    }
}
