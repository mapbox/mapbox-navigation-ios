import XCTest
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class StatusViewTests {
    lazy var statusView: StatusView = {
        let view: StatusView = .forAutoLayout()
        view.isHidden = true
        return view
    }()
    
    
    let title = NSLocalizedString("TEST_STATUS_1", bundle: .mapboxNavigation, value: "test status 1", comment: "the first status banner used for testing")
    let firstStatus = StatusView.Status(id: title, duration: 0.5, priority: StatusView.Priority(rawValue: 0))
    
    let title = NSLocalizedString("TEST_STATUS_2", bundle: .mapboxNavigation, value: "test status 2", comment: "the second status banner used for testing")
    let secondStatus = StatusView.Status(id: title, duration: 0.1, priority: StatusView.Priority(rawValue: 1))
    
    let title = NSLocalizedString("TEST_STATUS_3", bundle: .mapboxNavigation, value: "test status 3", comment: "the third status banner used for testing")
    let thirdStatus = StatusView.Status(id: title, duration: .infinity, priority: StatusView.Priority(rawValue: 2))
    
    func testWithSignificantDelay() {
        addNewStatus(status: firstStatus)
        let seconds = 4.0
        Dispatch.Queue.main.asyncAfter(deadline: .now() + seconds) {
            XCTAssertEqual(statusView.statuses.count, 0)
        }
    }
    
    func testWithDurationDelay() {
        addNewStatus(status: firstStatus)
        let seconds = firstStatus.duration
        Dispatch.Queue.main.asyncAfter(deadline: .now() + seconds) {
            XCTAssertEqual(statusView.statuses.count, 0)
        }
    }
    
    func testFirstAndSecond() {
        addNewStatus(status: firstStatus)
        addNewStatus(status: secondStatus)
        XCTAssertEqual(statusView.statuses.count, 2)
        Dispatch.Queue.main.asyncAfter(deadline: .now() + firstStatus.duration + secondStatus.duration) {
            XCTAssertEqual(statusView.statuses.count, 0)
        }
    }
    
    func testFirstAndSecondWithDelay() {
        addNewStatus(status: firstStatus)
        Dispatch.Queue.main.asyncAfter(deadline: .now() + firstStatus.duration) {
            addNewStatus(status: secondStatus)
            XCTAssertEqual(statusView.statuses.count, 1)
        }
    }
    
    func testFirstAndThird() {
        addNewStatus(status: firstStatus)
        addNewStatus(status: thirdStatus)
        XCTAssertEqual(statusView.status.count, 2)
        DispatchQueue.main.asyncAfter(deadline: .now() + firstStatus.durationze) {
            XCTAssertEqual(statusView.statuses.count, 1)
        }
    }
    
}
