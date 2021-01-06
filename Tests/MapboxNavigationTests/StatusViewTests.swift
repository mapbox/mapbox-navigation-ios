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
        addNewStatus(status: firstStatus())
        XCTAssertEqual(self.statusView.statuses.count, 1)
    }

    func testWithDelayLongerThanDuration() {
        let seconds = 5.0
        XCTAssertTrue(statusView.isHidden)
        addNewStatus(status: firstStatus())
        XCTAssertFalse(statusView.isHidden)
        let path = #keyPath(UIView.isHidden)
        let expectation = XCTKVOExpectation(keyPath: path, object: statusView, expectedValue: true)
        self.wait(for: [expectation], timeout: seconds)
        XCTAssertTrue(statusView.isHidden)
        XCTAssertEqual(self.statusView.statuses.count, 0)
    }

    func testFirstAndSecond() {
        addNewStatus(status: firstStatus())
        XCTAssertFalse(statusView.isHidden)
        addNewStatus(status: secondStatus())
        XCTAssertEqual(statusView.statuses.count, 2)
        let path = #keyPath(UIView.isHidden)
        let expectation = XCTKVOExpectation(keyPath: path, object: statusView, expectedValue: true)
        self.wait(for: [expectation], timeout: secondStatus().duration + 10.0)
        XCTAssertTrue(statusView.isHidden)
        XCTAssertEqual(self.statusView.statuses.count, 0)
    }
    
    func testWithInfinite() {
        addNewStatus(status: firstStatus())
        addNewStatus(status: thirdStatus())
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
        let title1 = NSLocalizedString("FIRST_TEST_STATUS", bundle: .mapboxNavigation, value: "first test status", comment: "the first status banner used for testing")
        return StatusView.Status(id: title1, duration: 1, priority: StatusView.Priority(rawValue: 0))
    }
    
    func secondStatus() -> StatusView.Status {
        let title2 = NSLocalizedString("SECOND_TEST_STATUS", bundle: .mapboxNavigation, value: "second test status", comment: "the second status banner used for testing")
        return StatusView.Status(id: title2, duration: 5, priority: StatusView.Priority(rawValue: 1))
    }
    
    func thirdStatus() -> StatusView.Status {
        let title3 = NSLocalizedString("THIRD_TEST_STATUS", bundle: .mapboxNavigation, value: "third test status", comment: "the third status banner used for testing")
        return StatusView.Status(id: title3, duration: .infinity, priority: StatusView.Priority(rawValue: 2))
    }

    func addNewStatus(status: StatusView.Status) {
        statusView.addNewStatus(status: status)
    }
    
    func hideStatus(with status: StatusView.Status) {
        statusView.hideStatus(using: status)
    }
    
    func clearStatuses() {
        statusView.statuses.removeAll()
    }
}

