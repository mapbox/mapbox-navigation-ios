import MapboxCommon_Private
@testable import MapboxNavigationCore
import XCTest

final class NavigationMovementMonitorTests: XCTestCase {
    private var monitor: NavigationMovementMonitor!
    private var observer1: MovementModeObserverSpy!
    private var observer2: MovementModeObserverSpy!

    override func setUp() {
        super.setUp()

        monitor = .init()
        observer1 = .init()
        observer2 = .init()
    }

    func testSetMovementInfo() {
        let movementInfo = MovementInfo(movementMode: [1: 10, 2: 90], movementProvider: .unknown)
        monitor.registerObserver(for: observer1)
        monitor.registerObserver(for: observer2)
        monitor.setMovementInfoForMode(movementInfo)

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
        XCTAssertEqual(observer1.movementInfo?.movementMode, [MovementMode.cycling.rawValue as NSNumber: 100])
        XCTAssertEqual(observer1.movementInfo?.movementProvider, .SDK)

        monitor.currentProfile = .walking
        XCTAssertEqual(observer1.movementInfo?.movementMode, [MovementMode.onFoot.rawValue as NSNumber: 100])

        monitor.currentProfile = .automobile
        XCTAssertEqual(observer1.movementInfo?.movementMode, [MovementMode.inVehicle.rawValue as NSNumber: 100])

        monitor.currentProfile = .automobileAvoidingTraffic
        XCTAssertEqual(observer1.movementInfo?.movementMode, [MovementMode.inVehicle.rawValue as NSNumber: 100])

        monitor.currentProfile = nil
        XCTAssertEqual(observer1.movementInfo?.movementMode, [MovementMode.unknown.rawValue as NSNumber: 50])

        monitor.currentProfile = .init(rawValue: "custom")
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
