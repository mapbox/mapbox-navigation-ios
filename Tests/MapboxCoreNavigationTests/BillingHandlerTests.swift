import Foundation
import XCTest
import CoreLocation
import TestHelper
import MapboxNavigationNative
import MapboxDirections
@testable import MapboxCoreNavigation

final class BillingHandlerTests: TestCase {
    private var billingService: BillingServiceMock!
    private var handler: BillingHandler!
    private var sessionUuid: UUID!
    private var freeRideToken: String!
    private var activeGuidanceToken: String!
    private var navigator: CoreNavigatorSpy!

    private let expectationsTimeout = 0.5

    override func setUp() {
        super.setUp()

        sessionUuid = UUID()
        freeRideToken = UUID().uuidString
        activeGuidanceToken = UUID().uuidString
        billingService = .init()
        handler = BillingHandler.__createMockedHandler(with: billingService,
                                                       navigatorType: CoreNavigatorSpy.self)
        navigator = CoreNavigatorSpy.shared
        billingService.onGetSKUTokenIfValid = { [unowned self] sessionType in
            switch sessionType {
            case .activeGuidance: return activeGuidanceToken
            case .freeDrive: return freeRideToken
            }
        }
    }

    override func tearDown() {
        super.tearDown()
        billingService = nil
        handler = nil
    }

    func testSessionStart() {
        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .stopped)

        let expectedSessionType = BillingHandler.SessionType.activeGuidance
        billingService.onStopBillingSession = { _ in
            XCTFail("Stop shouldn't be called")
        }

        let beginSessionExpectation = expectation(description: "Beging session triggered")
        billingService.onBeginBillingSession = { sessionType, _ in
            XCTAssertEqual(sessionType, expectedSessionType)
            beginSessionExpectation.fulfill()
        }

        let billingEventExpectation = expectation(description: "Billing event triggered")
        billingService.onTriggerBillingEvent = { _ in
            billingEventExpectation.fulfill()
        }

        handler.beginBillingSession(for: expectedSessionType, uuid: sessionUuid)

        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .running)
        billingService.assertEvents([
            .beginBillingSession(expectedSessionType),
        ])
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testResumeNavigatorWhenStarting() {
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)

        XCTAssertTrue(navigator.resumeCalled)
        XCTAssertFalse(navigator.pauseCalled)
    }

    func testDoNotResumeNavigatorWhenStartingIfNoSharedNavigatorInstanceCreated() {
        CoreNavigatorSpy.isSharedInstanceCreated = false
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)

        XCTAssertFalse(navigator.resumeCalled)
        XCTAssertFalse(navigator.pauseCalled)
    }

    func testPauseNavigatorWhenNoRunningSessions() {
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)
        navigator.reset()
        handler.pauseBillingSession(with: sessionUuid)

        XCTAssertFalse(navigator.resumeCalled)
        XCTAssertTrue(navigator.pauseCalled)
    }

    func testResumeNavigatorWhenResuming() {
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)
        handler.pauseBillingSession(with: sessionUuid)
        navigator.reset()
        handler.resumeBillingSession(with: sessionUuid)

        XCTAssertTrue(navigator.resumeCalled)
        XCTAssertFalse(navigator.pauseCalled)
    }

    func testPauseNavigatorWhenStopping() {
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)
        navigator.reset()
        handler.stopBillingSession(with: sessionUuid)

        XCTAssertFalse(navigator.resumeCalled)
        XCTAssertTrue(navigator.pauseCalled)
    }

    func testSessionStop() {
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)

        let billingEventExpectation = expectation(description: "Billing event should not be triggered when stopping")
        billingEventExpectation.isInverted = true
        billingService.onTriggerBillingEvent = { _ in
            billingEventExpectation.fulfill()
        }
        let stopSessionExpectation = expectation(description: "Session stopped")
        billingService.onStopBillingSession = { sessionType in
            XCTAssertEqual(sessionType, .activeGuidance)
            stopSessionExpectation.fulfill()
        }

        handler.stopBillingSession(with: self.sessionUuid)

        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .stopped)
        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
            .stopBillingSession(.activeGuidance),
        ])
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testSessionPause() {
        handler.beginBillingSession(for: .freeDrive, uuid: sessionUuid)

        let billingEventTriggered = expectation(description: "Billing event should not be triggered when stopping")
        billingEventTriggered.isInverted = true
        billingService.onTriggerBillingEvent = { _ in
            billingEventTriggered.fulfill()
        }

        let stopSessionExpectation = expectation(description: "Session should not be stopped")
        stopSessionExpectation.isInverted = true
        billingService.onStopBillingSession = { _ in
            stopSessionExpectation.fulfill()
        }

        let sessionPausedExpectation = expectation(description: "Session paused")
        billingService.onPauseBillingSession = { sessionType in
            XCTAssertEqual(sessionType, .freeDrive)
            sessionPausedExpectation.fulfill()
        }

        handler.pauseBillingSession(with: sessionUuid)
        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .paused)
        billingService.assertEvents([
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive),
        ])
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testSessionResumeAfterPause() {
        handler.beginBillingSession(for: .freeDrive, uuid: sessionUuid)
        handler.pauseBillingSession(with: sessionUuid)

        let billingSessionResumedExpectation = expectation(description: "Billing session resumed")
        billingService.onResumeBillingSession = { sessionType, _ in
            XCTAssertEqual(sessionType, .freeDrive)
            billingSessionResumedExpectation.fulfill()
        }

        handler.resumeBillingSession(with: sessionUuid)

        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .running)
        billingService.assertEvents([
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive),
            .resumeBillingSession(.freeDrive),
        ])
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testSessionResumeFailed() {
        let expectedSessionType = BillingHandler.SessionType.activeGuidance
        handler.beginBillingSession(for: expectedSessionType, uuid: sessionUuid)
        handler.pauseBillingSession(with: sessionUuid)

        let sessionStartedExpectation = expectation(description: "Session started second time")
        billingService.onBeginBillingSession = { sessionType, _ in
            XCTAssertEqual(sessionType, expectedSessionType)
            sessionStartedExpectation.fulfill()
        }
        let billingSessionResumedExpectation = expectation(description: "Billing session resumed")
        billingService.onResumeBillingSession = { sessionType, onError in
            DispatchQueue.global().async {
                onError(.resumeFailed)
            }
            XCTAssertEqual(sessionType, expectedSessionType)
            billingSessionResumedExpectation.fulfill()
        }

        handler.resumeBillingSession(with: sessionUuid)

        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .running)
        waitForExpectations(timeout: expectationsTimeout)

        billingService.assertEvents([
            .beginBillingSession(expectedSessionType),
            .pauseBillingSession(expectedSessionType),
            .resumeBillingSession(expectedSessionType),
            .beginBillingSession(expectedSessionType),
        ])
    }

    func testSessionBeginFailed() {
        let sessionFailed = expectation(description: "Session Failed")
        billingService.onBeginBillingSession = { _, onError in
            DispatchQueue.global().async {
                onError(.unknown)
                sessionFailed.fulfill()
            }
        }
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)
        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .running)
        waitForExpectations(timeout: expectationsTimeout)
        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .stopped)

        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
        ])
    }

    func testSessionStartIfExistsWhenNotStarted() {
        let beginSessionExpectation = expectation(description: "Beging session should not be triggered")
        beginSessionExpectation.isInverted = true
        billingService.onBeginBillingSession = { _, _ in
            beginSessionExpectation.fulfill()
        }
        let billingEventExpectation = expectation(description: "Billing should not be triggered")
        billingEventExpectation.isInverted = true
        billingService.onTriggerBillingEvent = { _ in
            billingEventExpectation.fulfill()
        }

        handler.beginNewBillingSessionIfExists(with: sessionUuid)

        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .stopped)
        billingService.assertEvents([])
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testSessionStartIfExistsAndRunning() {
        let expectedSessionType = BillingHandler.SessionType.activeGuidance
        handler.beginBillingSession(for: expectedSessionType, uuid: sessionUuid)

        let beginSessionExpectation = expectation(description: "Beging session should be triggered")
        billingService.onBeginBillingSession = { sessionType, _ in
            XCTAssertEqual(sessionType, expectedSessionType)
            beginSessionExpectation.fulfill()
        }
        let billingEventExpectation = expectation(description: "Billing should not be triggered")
        billingEventExpectation.isInverted = true
        billingService.onTriggerBillingEvent = { _ in
            billingEventExpectation.fulfill()
        }

        let sessionPausedExpectation = expectation(description: "Pause should not be triggered")
        sessionPausedExpectation.isInverted = true
        billingService.onPauseBillingSession = { _ in
            sessionPausedExpectation.fulfill()
        }

        handler.beginNewBillingSessionIfExists(with: sessionUuid)

        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .running)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testSessionStartIfExistsAndPaused() {
        let expectedSessionType = BillingHandler.SessionType.activeGuidance
        handler.beginBillingSession(for: expectedSessionType, uuid: sessionUuid)
        handler.pauseBillingSession(with: sessionUuid)

        let beginSessionExpectation = expectation(description: "Beging session should be triggered")
        billingService.onBeginBillingSession = { sessionType, _ in
            XCTAssertEqual(sessionType, expectedSessionType)
            beginSessionExpectation.fulfill()
        }
        let billingEventExpectation = expectation(description: "Billing should not be triggered")
        billingEventExpectation.isInverted = true
        billingService.onTriggerBillingEvent = { _ in
            billingEventExpectation.fulfill()
        }

        let sessionPausedExpectation = expectation(description: "Session paused")
        billingService.onPauseBillingSession = { sessionType in
            XCTAssertEqual(sessionType, expectedSessionType)
            sessionPausedExpectation.fulfill()
        }

        handler.beginNewBillingSessionIfExists(with: sessionUuid)

        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .paused)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testSessionFailedToStartIfExistsAndRunning() {
        let expectedSessionType = BillingHandler.SessionType.activeGuidance
        let expectedError = BillingServiceError.unknown
        handler.beginBillingSession(for: expectedSessionType, uuid: sessionUuid)

        let beginSessionExpectation = expectation(description: "Beging session should be triggered")
        billingService.onBeginBillingSession = { sessionType, onError in
            XCTAssertEqual(sessionType, expectedSessionType)
            beginSessionExpectation.fulfill()
            onError(expectedError)
        }

        handler.beginNewBillingSessionIfExists(with: sessionUuid)

        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .running)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testFailedMauBillingDoNotStopSession() {
        let billingEventTriggered = expectation(description: "Billing event triggered")
        let beginSessionTriggered = expectation(description: "Begin session triggered")
        billingService.onTriggerBillingEvent = { onError in
            DispatchQueue.global().async {
                onError(.tokenValidationFailed)
                billingEventTriggered.fulfill()
            }
        }
        billingService.onBeginBillingSession = { _, _ in
            beginSessionTriggered.fulfill()
        }
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)
        waitForExpectations(timeout: 2)
        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .running)

        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
        ])
    }

    /// If two sessions starts, one after another, and then the first one stopped, the billing session should continue.
    func testTwoSessionsWithOneStopped() {
        let finished = expectation(description: "Finished")
        let queue = DispatchQueue(label: "")
        queue.async {
            self.handler.beginBillingSession(for: .freeDrive, uuid: UUID())
        }
        queue.async {
            self.handler.beginBillingSession(for: .activeGuidance, uuid: self.sessionUuid)
            queue.async {
                self.handler.stopBillingSession(with: self.sessionUuid)
                finished.fulfill()
            }
        }
        waitForExpectations(timeout: expectationsTimeout)

        billingService.assertEvents([
            .beginBillingSession(.freeDrive),
            .beginBillingSession(.activeGuidance),
            .stopBillingSession(.activeGuidance)
        ])
    }

    func testTwoSessionsWithResumeFailed() {
        let sessionStarted = expectation(description: "Session started")
        let sessionStopped = expectation(description: "Session stopped")
        sessionStarted.expectedFulfillmentCount = 3
        sessionStopped.expectedFulfillmentCount = 2
        billingService.onBeginBillingSession = { _, onError in
            sessionStarted.fulfill()
        }
        billingService.onStopBillingSession = { _ in
            sessionStopped.fulfill()
        }
        billingService.onResumeBillingSession = { _, onError in
            onError(.resumeFailed)
        }
        let queue = DispatchQueue(label: "")
        let freeDriveSessionUUID = UUID()
        let activeGuidanceSessionUUID = UUID()

        queue.async {
            self.handler.beginBillingSession(for: .freeDrive, uuid: freeDriveSessionUUID)
        }
        queue.async {
            self.handler.beginBillingSession(for: .activeGuidance, uuid: activeGuidanceSessionUUID)
        }
        queue.async {
            self.handler.pauseBillingSession(with: activeGuidanceSessionUUID)
        }
        queue.async {
            self.handler.resumeBillingSession(with: activeGuidanceSessionUUID)
        }
        queue.async {
            self.handler.stopBillingSession(with: activeGuidanceSessionUUID)
        }
        queue.async {
            self.handler.stopBillingSession(with: freeDriveSessionUUID)
        }
        waitForExpectations(timeout: 5)
        billingService.assertEvents([
            .beginBillingSession(.freeDrive),
            .beginBillingSession(.activeGuidance),
            .pauseBillingSession(.activeGuidance),
            .resumeBillingSession(.activeGuidance),
            .beginBillingSession(.activeGuidance),
            .stopBillingSession(.activeGuidance),
            .stopBillingSession(.freeDrive),
        ])
    }

    func testTokens() {
        let freeDriveSessionUUID = UUID()
        let activeGuidanceSessionUUID = UUID()
        handler.beginBillingSession(for: .freeDrive, uuid: freeDriveSessionUUID)
        XCTAssertEqual(handler.serviceSkuToken, freeRideToken)
        handler.beginBillingSession(for: .activeGuidance, uuid: activeGuidanceSessionUUID)
        XCTAssertEqual(handler.serviceSkuToken, activeGuidanceToken)
        handler.pauseBillingSession(with: activeGuidanceSessionUUID)
        XCTAssertEqual(handler.serviceSkuToken, freeRideToken)
        handler.pauseBillingSession(with: freeDriveSessionUUID)
        XCTAssertEqual(handler.serviceSkuToken, "")
        handler.resumeBillingSession(with: freeDriveSessionUUID)
        XCTAssertEqual(handler.serviceSkuToken, freeRideToken)
        handler.resumeBillingSession(with: activeGuidanceSessionUUID)
        XCTAssertEqual(handler.serviceSkuToken, activeGuidanceToken)
        handler.stopBillingSession(with: activeGuidanceSessionUUID)
        XCTAssertEqual(handler.serviceSkuToken, freeRideToken)
        handler.stopBillingSession(with: freeDriveSessionUUID)
        XCTAssertEqual(handler.serviceSkuToken, "")
    }

    func testStartingFreeRideAfterActiveGuidance() {
        handler.beginBillingSession(for: .activeGuidance, uuid: .init())
        XCTAssertEqual(handler.serviceSkuToken, activeGuidanceToken)
        handler.beginBillingSession(for: .freeDrive, uuid: .init())
        XCTAssertEqual(handler.serviceSkuToken, activeGuidanceToken)
    }

    func testSessionStoppedForNonExistingUUID() {
        XCTAssertEqual(billingService.getSessionStatus(for: .activeGuidance), .stopped)
        XCTAssertEqual(handler.sessionState(uuid: UUID()), .stopped)
    }

    func testOneBillingSessionForTwoSameRideSession() {
        let session1UUID = UUID()
        let session2UUID = UUID()
        handler.beginBillingSession(for: .activeGuidance, uuid: session1UUID)
        handler.beginBillingSession(for: .activeGuidance, uuid: session2UUID)
        XCTAssertEqual(billingService.getSessionStatus(for: .activeGuidance), .running)
        handler.stopBillingSession(with: session1UUID)
        XCTAssertEqual(handler.sessionState(uuid: session1UUID), .stopped)
        XCTAssertEqual(handler.sessionState(uuid: session2UUID), .running)
        XCTAssertEqual(billingService.getSessionStatus(for: .activeGuidance), .running)
        handler.stopBillingSession(with: session2UUID)
        XCTAssertEqual(handler.sessionState(uuid: session2UUID), .stopped)
        XCTAssertEqual(billingService.getSessionStatus(for: .activeGuidance), .stopped)

        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
            .stopBillingSession(.activeGuidance)
        ])
    }

    func testTwoBillingSessionForTwoSameRideSession() {
        let activeGuidanceSession1UUID = UUID()
        let activeGuidanceSession2UUID = UUID()
        let freeRideSession1UUID = UUID()
        let freeRideSession2UUID = UUID()

        handler.beginBillingSession(for: .activeGuidance, uuid: activeGuidanceSession1UUID)
        handler.beginBillingSession(for: .activeGuidance, uuid: activeGuidanceSession2UUID)
        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession1UUID)
        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession2UUID)
        handler.stopBillingSession(with: activeGuidanceSession1UUID)
        handler.stopBillingSession(with: activeGuidanceSession2UUID)
        handler.stopBillingSession(with: freeRideSession2UUID)
        handler.stopBillingSession(with: freeRideSession1UUID)

        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
            .beginBillingSession(.freeDrive),
            .stopBillingSession(.activeGuidance),
            .stopBillingSession(.freeDrive)
        ])
    }

    /// A test case with quite complex configuration
    func testComplexUsecase() {
        let activeGuidanceSession1UUID = UUID()
        let activeGuidanceSession2UUID = UUID()
        let freeRideSession1UUID = UUID()
        let freeRideSession2UUID = UUID()

        handler.beginBillingSession(for: .activeGuidance, uuid: activeGuidanceSession1UUID)
        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession1UUID)
        handler.beginBillingSession(for: .activeGuidance, uuid: activeGuidanceSession2UUID)
        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession2UUID)
        handler.pauseBillingSession(with: freeRideSession1UUID)
        handler.pauseBillingSession(with: activeGuidanceSession1UUID)
        handler.resumeBillingSession(with: activeGuidanceSession1UUID)
        handler.resumeBillingSession(with: freeRideSession1UUID)
        handler.pauseBillingSession(with: freeRideSession1UUID)
        handler.pauseBillingSession(with: freeRideSession2UUID)
        handler.resumeBillingSession(with: freeRideSession1UUID)
        handler.stopBillingSession(with: activeGuidanceSession1UUID)
        handler.stopBillingSession(with: activeGuidanceSession2UUID)
        handler.pauseBillingSession(with: freeRideSession1UUID)
        handler.pauseBillingSession(with: freeRideSession2UUID)
        handler.stopBillingSession(with: freeRideSession2UUID)
        handler.stopBillingSession(with: freeRideSession1UUID)

        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive),
            .resumeBillingSession(.freeDrive),
            .stopBillingSession(.activeGuidance),
            .pauseBillingSession(.freeDrive),
            .stopBillingSession(.freeDrive),
        ])
    }

    func testPauseSessionWithStoppingSimilarOne() {
        let freeRideSession1UUID = UUID()
        let freeRideSession2UUID = UUID()

        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession1UUID)
        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession2UUID)
        handler.pauseBillingSession(with: freeRideSession1UUID)
        handler.stopBillingSession(with: freeRideSession2UUID)

        billingService.assertEvents([
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive),
        ])
    }

    func testBeginSessionWithPausedSimilarOne() {
        let freeRideSession1UUID = UUID()
        let freeRideSession2UUID = UUID()

        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession1UUID)
        handler.pauseBillingSession(with: freeRideSession1UUID)
        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession2UUID)

        billingService.assertEvents([
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive),
            .resumeBillingSession(.freeDrive)
        ])
    }

    func testBeginSessionWithPausedSimilarOneButFailed() {
        let freeRideSession1UUID = UUID()
        let freeRideSession2UUID = UUID()

        let resumeFailedCalled = expectation(description: "Resume Failed Called")
        billingService.onResumeBillingSession = { _, onError in
            DispatchQueue.global().async {
                onError(.resumeFailed)
                DispatchQueue.global().async {
                    resumeFailedCalled.fulfill()
                }
            }
        }

        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession1UUID)
        handler.pauseBillingSession(with: freeRideSession1UUID)
        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession2UUID)

        waitForExpectations(timeout: expectationsTimeout)

        billingService.assertEvents([
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive),
            .resumeBillingSession(.freeDrive),
            .beginBillingSession(.freeDrive),
        ])
    }

    func testServiceAccessToken() {
        let expectedAccessToken = UUID().uuidString
        billingServiceMock.accessToken = expectedAccessToken
        XCTAssertEqual(Accounts.serviceAccessToken, expectedAccessToken)
    }

    func testForceStartNewBillingSession() {
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)
        handler.beginNewBillingSessionIfExists(with: sessionUuid)
        
        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
            .beginBillingSession(.activeGuidance),
        ])
    }

    func testForceStartNewBillingSessionOnPausedSession() {
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)
        handler.pauseBillingSession(with: sessionUuid)
        handler.beginNewBillingSessionIfExists(with: sessionUuid)
        handler.resumeBillingSession(with: sessionUuid)

        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
            .pauseBillingSession(.activeGuidance),
            .beginBillingSession(.activeGuidance),
            .pauseBillingSession(.activeGuidance),
            .resumeBillingSession(.activeGuidance),
        ])
    }

    func testForceStartNewBillingSessionOnNonExistentSession() {
        handler.beginNewBillingSessionIfExists(with: sessionUuid)

        billingService.assertEvents([])
    }

    func testForceStartNewBillingSessionOnPausedSessionFreeDrive() {
        handler.beginBillingSession(for: .freeDrive, uuid: sessionUuid)
        handler.pauseBillingSession(with: sessionUuid)
        handler.beginNewBillingSessionIfExists(with: sessionUuid)
        handler.resumeBillingSession(with: sessionUuid)

        billingService.assertEvents([
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive),
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive),
            .resumeBillingSession(.freeDrive),
        ])
    }

    func testForceStartNewBillingSessionOnPausedSessionWithOneActive() {
        let sessionUuid = UUID()
        let sessionUuid2 = UUID()
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid2)
        handler.pauseBillingSession(with: sessionUuid)
        handler.beginNewBillingSessionIfExists(with: sessionUuid)
        handler.resumeBillingSession(with: sessionUuid)

        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
            .beginBillingSession(.activeGuidance),
        ])
    }

    func testStressTest() {
        let finished = expectation(description: "Finished")
        DispatchQueue.global().async {
            DispatchQueue.concurrentPerform(iterations: 1000) { iterationIdx in
                let sessionUuid = UUID()
                let sessionType = BillingHandler.SessionType.random()
                self.handler.beginBillingSession(for: sessionType, uuid: sessionUuid)
                self.handler.pauseBillingSession(with: sessionUuid)
                self.handler.beginNewBillingSessionIfExists(with: sessionUuid)
                self.handler.resumeBillingSession(with: sessionUuid)
                self.handler.stopBillingSession(with: sessionUuid)
            }
            finished.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}

private extension BillingHandler.SessionType {
    static func random() -> Self {
        if (0..<1).randomElement()! == 0 {
            return .freeDrive
        }
        else {
            return .activeGuidance
        }
    }
}
