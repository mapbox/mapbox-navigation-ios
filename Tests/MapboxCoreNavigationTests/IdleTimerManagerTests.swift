import Foundation
import XCTest
import TestHelper
@testable import MapboxNavigation

final class IdleTimerSpy: IdleTimer {
    private let lock: NSLock = .init()
    var isDisabled: Bool = false

    func setDisabled(_ disabled: Bool) {
        lock.lock(); defer {
            lock.unlock()
        }
        isDisabled = disabled
    }
}

final class IdleTimerManagerTests: TestCase {
    private var idleManager: IdleTimerManager!
    private var idleTimer: IdleTimerSpy!

    override func setUp() {
        super.setUp()
        idleTimer = IdleTimerSpy()
        idleManager = .init(idleTimer: idleTimer)
    }

    func testOneRequestToDisable() {
        withExtendedLifetime(idleManager.disableIdleTimer()) {
            XCTAssertEqual(idleTimer.isDisabled, true)
        }
        XCTAssertEqual(idleTimer.isDisabled, false)
    }

    func testMultipleRequestsToDisable() {
        withExtendedLifetime(idleManager.disableIdleTimer()) {
            XCTAssertEqual(idleTimer.isDisabled, true)
            withExtendedLifetime(idleManager.disableIdleTimer()) {
                XCTAssertEqual(idleTimer.isDisabled, true)
            }
            XCTAssertEqual(idleTimer.isDisabled, true)
        }
        XCTAssertEqual(idleTimer.isDisabled, false)
    }

    func testThreadSafety() {
        let lock: NSLock = .init()
        var cancellables: [IdleTimerManager.Cancellable] = []

        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            lock.lock(); defer {
                lock.unlock()
            }
            cancellables.append(idleManager.disableIdleTimer())
        }

        expectation(description: "Idle Timer Disabled") {
            !self.idleTimer.isDisabled
        }

        DispatchQueue.global().async {
            cancellables.removeAll()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}
