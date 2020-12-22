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
//        let seconds = 4.0

        XCTAssertEqual(self.statusView.statuses.count, 1)
    }
    
    func testWithDelayLongerThanDuration() {
        let seconds = 10.0
        XCTAssertTrue(statusView.isHidden)
        addNewStatus(status: firstStatus())
        XCTAssertFalse(statusView.isHidden)
        let path = #keyPath(UIView.isHidden)
        let expectation = XCTKVOExpectation(keyPath: path, object: statusView, expectedValue: true)
        self.wait(for: [expectation], timeout: seconds)
        XCTAssertTrue(statusView.isHidden)
        XCTAssertEqual(self.statusView.statuses.count, 0)
    }
//
//    func testWithDurationDelay() {
//        addNewStatus(status: firstStatus())
//        let seconds = firstStatus().duration
//        Thread.sleep(forTimeInterval: seconds)
//        XCTAssertEqual(self.statusView.statuses.count, 0)
//    }
//
//    func testFirstAndSecond() {
//        addNewStatus(status: firstStatus())
//        XCTAssertEqual(statusView.statuses.count, 1)
//        addNewStatus(status: secondStatus())
//        XCTAssertEqual(statusView.statuses.count, 2)
//        Thread.sleep(forTimeInterval: firstStatus().duration + secondStatus().duration)
//        XCTAssertEqual(self.statusView.statuses.count, 0)
//    }
//
//    func testFirstAndSecondWithDelay() {
//        addNewStatus(status: firstStatus())
//        Thread.sleep(forTimeInterval: firstStatus().duration)
//        self.addNewStatus(status: self.secondStatus())
//        XCTAssertEqual(self.statusView.statuses.count, 1)
//    }
//
//    func testFirstAndThird() {
//        print("!!! statuses before reset: \(statusView.statuses)")
//        clearStatuses()
//        addNewStatus(status: firstStatus())
//        addNewStatus(status: thirdStatus())
//        XCTAssertEqual(self.statusView.statuses.count, 2)
//        Thread.sleep(forTimeInterval: firstStatus().duration)
//        XCTAssertEqual(self.statusView.statuses.count, 1)
//    }
}

extension StatusViewTests {
    
    // define statuses
    func firstStatus() -> StatusView.Status {
        let title1 = NSLocalizedString("FIRST_TEST_STATUS", bundle: .mapboxNavigation, value: "first test status", comment: "the first status banner used for testing")
        return StatusView.Status(id: title1, duration: 5, priority: StatusView.Priority(rawValue: 0))
    }
    
    func secondStatus() -> StatusView.Status {
        let title2 = NSLocalizedString("SECOND_TEST_STATUS", bundle: .mapboxNavigation, value: "second test status", comment: "the second status banner used for testing")
        return StatusView.Status(id: title2, duration: 10, priority: StatusView.Priority(rawValue: 1))
    }
    
    func thirdStatus() -> StatusView.Status {
        let title3 = NSLocalizedString("THIRD_TEST_STATUS", bundle: .mapboxNavigation, value: "third test status", comment: "the third status banner used for testing")
        return StatusView.Status(id: title3, duration: .infinity, priority: StatusView.Priority(rawValue: 2))
    }
    
    func fourthStatus() -> StatusView.Status {
        let title4 = NSLocalizedString("FOURTH_TEST_STATUS", bundle: .mapboxNavigation, value: "fourth test status", comment: "the fourth status banner used for testing")
        return StatusView.Status(id: title4, duration: 0.5, priority: StatusView.Priority(rawValue: 3))
    }

    func addNewStatus(status: StatusView.Status) {
        statusView.addNewStatus(status: status)
    }
    
    func hideStatus(status: StatusView.Status) {
        statusView.hideStatus(usingStatus: status)
    }
    
    func clearStatuses() {
        statusView.statuses.removeAll()
    }
    
}

