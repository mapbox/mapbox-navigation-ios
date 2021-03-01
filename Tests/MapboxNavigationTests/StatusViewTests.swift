import XCTest
import UIKit
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class StatusViewTests: XCTestCase {
    lazy var statusView: StatusView = {
        let view: StatusView = .forAutoLayout()
        view.isHidden = true
        return view
    }()

    func testWithDelayShorterThanDuration() {
        show(firstStatus())
        XCTAssertEqual(self.statusView.statuses.count, 1)
    }

    func testWithDelayLongerThanDuration() {
        let seconds = 5.0
        XCTAssertTrue(statusView.isHidden)
        show(firstStatus())
        XCTAssertFalse(statusView.isHidden)
        let path = #keyPath(UIView.isHidden)
        let expectation = XCTKVOExpectation(keyPath: path, object: statusView, expectedValue: true)
        self.wait(for: [expectation], timeout: seconds)
        XCTAssertTrue(statusView.isHidden)
        XCTAssertEqual(self.statusView.statuses.count, 0)
    }

    func testFirstAndSecond() {
        show(firstStatus())
        XCTAssertFalse(statusView.isHidden)
        show(secondStatus())
        XCTAssertEqual(statusView.statuses.count, 2)
        let path = #keyPath(UIView.isHidden)
        let expectation = XCTKVOExpectation(keyPath: path, object: statusView, expectedValue: true)
        self.wait(for: [expectation], timeout: secondStatus().duration + 10.0)
        XCTAssertTrue(statusView.isHidden)
        XCTAssertEqual(self.statusView.statuses.count, 0)
    }
    
    func testWithInfinite() {
        show(firstStatus())
        show(thirdStatus())
        XCTAssertEqual(self.statusView.statuses.count, 2)
        let path = #keyPath(UIView.isHidden)
        let expectation = XCTKVOExpectation(keyPath: path, object: statusView, expectedValue: true)
        XCTWaiter.wait(for: [expectation], timeout: 15.0)
        XCTAssertFalse(statusView.isHidden)
        XCTAssertEqual(self.statusView.statuses.count, 1)
    }
}

extension StatusViewTests {
    
    // define statuses
    func firstStatus() -> StatusView.Status {
        return StatusView.Status(id: "first test status", duration: 1, priority: StatusView.Priority(rawValue: 0))
    }
    
    func secondStatus() -> StatusView.Status {
        return StatusView.Status(id: "second test status", duration: 5, priority: StatusView.Priority(rawValue: 1))
    }
    
    func thirdStatus() -> StatusView.Status {
        return StatusView.Status(id: "third test status", duration: .infinity, priority: StatusView.Priority(rawValue: 2))
    }

    func show(_ status: StatusView.Status) {
        statusView.show(status)
    }
    
    func hide(_ status: StatusView.Status) {
        statusView.hide(status)
    }
    
    func clearStatuses() {
        statusView.statuses.removeAll()
    }
}

