import XCTest
import UIKit
import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class StatusViewTests: TestCase {
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
        self.wait(for: [expectation], timeout: secondStatus().duration + 1)
        XCTAssertTrue(statusView.isHidden)
        XCTAssertEqual(self.statusView.statuses.count, 0)
    }
    
    func testWithInfinite() {
        show(firstStatus())
        show(thirdStatus())
        XCTAssertEqual(self.statusView.statuses.count, 2)
        let path = #keyPath(UIView.isHidden)
        let expectation = XCTKVOExpectation(keyPath: path, object: statusView, expectedValue: true)
        let result = XCTWaiter.wait(for: [expectation], timeout: 1)
        print(result.rawValue)
        XCTAssertFalse(statusView.isHidden)
        XCTAssertEqual(self.statusView.statuses.count, 1)
    }
}

extension StatusViewTests {
    
    // define statuses
    func firstStatus() -> StatusView.Status {
        return StatusView.Status(identifier: "FIRST_TEST_STATUS", title: "first test status", duration: 0.1, priority: 0)
    }
    
    func secondStatus() -> StatusView.Status {
        return StatusView.Status(identifier: "SECOND_TEST_STATUS", title: "second test status", duration: 0.1, priority: 1)
    }
    
    func thirdStatus() -> StatusView.Status {
        return StatusView.Status(identifier: "THIRD_TEST_STATUS", title: "third test status", duration: .infinity, priority: 2)
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

