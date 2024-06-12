import CoreLocation
@testable import MapboxNavigationCore
import XCTest

final class HistoryReplayControllerTests: XCTestCase {
    var historyReader: HistoryReader!
    var replayController: HistoryReplayController!

    override func setUp() {
        super.setUp()

        historyReader = .init(
            fileUrl: Bundle.module.url(
                forResource: "history_replay",
                withExtension: "gz",
                subdirectory: "Fixtures"
            )!
        )
        replayController = HistoryReplayController(historyReader: historyReader)
    }

    func testLocationPush() {
        // Arrange
        let expectation = expectation(description: "Location should be pushed.")
        expectation.assertForOverFulfill = true
        let testLocation = CLLocation(latitude: 1, longitude: 2)
        let cancellable = replayController.locations
            .sink {
                // Assert
                if $0 == testLocation {
                    expectation.fulfill()
                }
            }

        // Act
        replayController.play()
        replayController.push(location: testLocation)

        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error, "Expectation waiting error: \(error!)")
        }
        cancellable.cancel()
    }

    func testPlaybackSpeed() {
        // Arrange
        let delegateSpy = HistoryReplayDelegateSpy()
        replayController.delegate = delegateSpy
        let speedMultiplier = 3.0
        var previousEventTimestamp: TimeInterval? = nil
        let expectation =
            expectation(description: "Events real timestamp difference should match the speed multiplier.")
        expectation.assertForOverFulfill = false
        expectation.isInverted = true
        replayController.speedMultiplier = 3

        delegateSpy.onEvent = { _ in
            // Assert
            defer {
                previousEventTimestamp = Date().timeIntervalSince1970
            }
            guard let previousEventTimestamp else {
                return
            }

            // give a 10% time threshold for imprecise timer scheduling.
            if (Date().timeIntervalSince1970 - previousEventTimestamp) * 0.9 > (1.0 / speedMultiplier) {
                expectation.fulfill()
            }
        }

        // Act
        replayController.play()

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error, "Expectation waiting error: \(error!)")
        }
    }

    func testPlaybackPausing() {
        // Arrange
        let delegateSpy = HistoryReplayDelegateSpy()
        replayController.delegate = delegateSpy
        let eventsPlayingExpectation = XCTestExpectation(description: "Events are arriving.")
        eventsPlayingExpectation.assertForOverFulfill = false

        let eventsPausedExpectation = XCTestExpectation(description: "Events are paused.")
        eventsPausedExpectation.isInverted = true
        let eventsResumedExpectation = XCTestExpectation(description: "Events are arriving after pause.")
        eventsResumedExpectation.assertForOverFulfill = false

        // play
        delegateSpy.onEvent = { _ in
            eventsPlayingExpectation.fulfill()
        }
        replayController.play()
        wait(
            for: [eventsPlayingExpectation],
            timeout: 2
        )

        // pause
        replayController.pause()
        delegateSpy.onEvent = { _ in
            eventsPausedExpectation.fulfill()
        }
        wait(
            for: [eventsPausedExpectation],
            timeout: 3
        )

        // resume
        delegateSpy.onEvent = { _ in
            eventsResumedExpectation.fulfill()
        }

        replayController.play()
        wait(
            for: [eventsResumedExpectation],
            timeout: 2
        )
    }

    func testSeekToOffset() async {
        // Arrange
        let controlReader = HistoryReader(
            fileUrl: Bundle.module.url(
                forResource: "history_replay",
                withExtension: "gz",
                subdirectory: "Fixtures"
            )!
        )!
        let firstEventTimestamp = await controlReader.first { _ in
            true
        }!.timestamp
        let delegateSpy = HistoryReplayDelegateSpy()
        replayController.delegate = delegateSpy
        let timeIntervalOffset: TimeInterval = 5
        let expectation =
            XCTestExpectation(description: "First event should be offset by \(timeIntervalOffset) seconds")
        expectation.isInverted = true
        delegateSpy.onEvent = {
            // Assert
            self.replayController.pause()
            if $0.timestamp - firstEventTimestamp < timeIntervalOffset {
                expectation.fulfill()
            }
        }

        // Act
        let seekSucceeded = await replayController.seekTo(offset: timeIntervalOffset)
        XCTAssertTrue(seekSucceeded)

        replayController.play()

        await fulfillment(of: [expectation], timeout: 2)
        delegateSpy.onEvent = { _ in }
    }

    func testSeekToEvent() async {
        // Arrange
        let controlReader = HistoryReader(
            fileUrl: Bundle.module.url(
                forResource: "history_replay",
                withExtension: "gz",
                subdirectory: "Fixtures"
            )!
        )!
        let setRouteEvent = await controlReader.first {
            $0 is RouteAssignmentHistoryEvent
        }!
        let delegateSpy = HistoryReplayDelegateSpy()
        replayController.delegate = delegateSpy
        let expectation = XCTestExpectation(description: "First event should be offset a setRoute")
        delegateSpy.onEvent = {
            // Assert
            self.replayController.pause()
            if $0.compare(to: setRouteEvent) {
                expectation.fulfill()
            }
        }

        // Act
        let seekSucceeded = await replayController.seekTo(event: setRouteEvent)
        XCTAssertTrue(seekSucceeded)

        replayController.play()

        await fulfillment(of: [expectation], timeout: 2)
        delegateSpy.onEvent = { _ in }
    }
}

final class HistoryReplayDelegateSpy: HistoryReplayDelegate, @unchecked Sendable {
    var onEvent: ((any HistoryEvent) -> Void)?
    var onSetRoutes: ((NavigationRoutes) -> Void)?
    var onFinish: (() -> Void)?

    func historyReplayController(
        _: MapboxNavigationCore.HistoryReplayController,
        didReplayEvent event: any MapboxNavigationCore.HistoryEvent
    ) {
        onEvent?(event)
    }

    func historyReplayController(
        _: MapboxNavigationCore.HistoryReplayController,
        wantsToSetRoutes routes: MapboxNavigationCore.NavigationRoutes
    ) {
        onSetRoutes?(routes)
    }

    func historyReplayControllerDidFinishReplay(_: MapboxNavigationCore.HistoryReplayController) {
        onFinish?()
    }
}
