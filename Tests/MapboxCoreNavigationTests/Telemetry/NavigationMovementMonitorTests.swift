@_implementationOnly import MapboxCommon_Private
@testable import MapboxCoreNavigation
import XCTest

final class NavigationMovementMonitorTests: XCTestCase {
    private var monitor: NavigationMovementMonitor!
    private var observer1: MovementModeObserverSpy!
    private var observer2: MovementModeObserverSpy!
    private var testQueue: DispatchQueue!

    override func setUp() {
        super.setUp()

        testQueue = DispatchQueue(label: "test")
        monitor = NavigationMovementMonitor(queue: testQueue)
        observer1 = MovementModeObserverSpy()
        observer2 = MovementModeObserverSpy()
    }

    func testSetMovementInfo() {
        let movementInfo = MovementInfo(movementMode: [1: 10, 2: 90], movementProvider: .unknown)
        monitor.registerObserver(for: observer1)
        monitor.registerObserver(for: observer2)
        monitor.setMovementInfoForMode(movementInfo)

        testQueue.sync {}
        XCTAssertEqual(observer1.movementInfo, movementInfo)
        XCTAssertEqual(observer2.movementInfo, movementInfo)
    }

    func testUnregisterObserver() {
        let movementInfo = MovementInfo(movementMode: [1: 10, 2: 90], movementProvider: .unknown)
        monitor.registerObserver(for: observer1)
        monitor.registerObserver(for: observer2)
        monitor.setMovementInfoForMode(movementInfo)

        let movementInfo2 = MovementInfo(movementMode: [1: 100], movementProvider: .SDK)
        monitor.unregisterObserver(for: observer1)

        monitor.setMovementInfoForMode(movementInfo2)

        testQueue.sync {}
        XCTAssertEqual(observer1.movementInfo, movementInfo)
        XCTAssertEqual(observer2.movementInfo, movementInfo2)
    }

    func testGetMovementInfo() {
        var movementInfo: MovementInfo?
        monitor.getMovementInfo { expected in
            XCTAssertFalse(expected.isError())
            XCTAssertTrue(expected.isValue())
            movementInfo = expected.value
        }
        testQueue.sync {}
        let expectedValue = MovementInfo(
            movementMode: [MovementMode.unknown.rawValue as NSNumber: 50],
            movementProvider: .SDK
        )
        XCTAssertEqual(movementInfo?.movementMode, expectedValue.movementMode)
        XCTAssertEqual(movementInfo?.movementProvider, expectedValue.movementProvider)

        monitor.currentProfile = .automobileAvoidingTraffic
        monitor.getMovementInfo { expected in
            XCTAssertFalse(expected.isError())
            XCTAssertTrue(expected.isValue())
            movementInfo = expected.value
        }
        testQueue.sync {}
        let expectedValue2 = MovementInfo(
            movementMode: [MovementMode.inVehicle.rawValue as NSNumber: 100],
            movementProvider: .SDK
        )
        XCTAssertEqual(movementInfo?.movementMode, expectedValue2.movementMode)
        XCTAssertEqual(movementInfo?.movementProvider, expectedValue2.movementProvider)
    }

    func testNotifyAboutProfileChange() {
        monitor.registerObserver(for: observer1)

        monitor.currentProfile = .cycling
        XCTAssertEqual(monitor.currentProfile, .cycling)
        testQueue.sync {}
        XCTAssertEqual(observer1.movementInfo?.movementMode, [MovementMode.cycling.rawValue as NSNumber: 100])
        XCTAssertEqual(observer1.movementInfo?.movementProvider, .SDK)

        monitor.currentProfile = .walking
        XCTAssertEqual(monitor.currentProfile, .walking)
        testQueue.sync {}
        XCTAssertEqual(observer1.movementInfo?.movementMode, [MovementMode.onFoot.rawValue as NSNumber: 100])

        monitor.currentProfile = .automobile
        XCTAssertEqual(monitor.currentProfile, .automobile)
        testQueue.sync {}
        XCTAssertEqual(observer1.movementInfo?.movementMode, [MovementMode.inVehicle.rawValue as NSNumber: 100])

        monitor.currentProfile = .automobileAvoidingTraffic
        XCTAssertEqual(monitor.currentProfile, .automobileAvoidingTraffic)
        testQueue.sync {}
        XCTAssertEqual(observer1.movementInfo?.movementMode, [MovementMode.inVehicle.rawValue as NSNumber: 100])

        monitor.currentProfile = nil
        XCTAssertNil(monitor.currentProfile)
        testQueue.sync {}
        XCTAssertEqual(observer1.movementInfo?.movementMode, [MovementMode.unknown.rawValue as NSNumber: 50])

        monitor.currentProfile = .init(rawValue: "custom")
        testQueue.sync {}
        XCTAssertEqual(observer1.movementInfo?.movementMode, [MovementMode.inVehicle.rawValue as NSNumber: 50])
    }
}

private final class MovementModeObserverSpy: MovementModeObserver {
    var error: String?
    var movementInfo: MovementInfo?

    func onMovementModeChanged(for movementInfo: MovementInfo) {
        self.movementInfo = movementInfo
    }

    func onMovementModeError(forError error: String) {
        self.error = error
    }
}

extension MovementInfo {
    fileprivate static func equals(_ lhs: MovementInfo, _ rhs: MovementInfo) -> Bool {
        lhs.movementMode == rhs.movementMode &&
        lhs.movementProvider == rhs.movementProvider
    }
}
