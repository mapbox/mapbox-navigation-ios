import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation

class SpeedLimitSignTests: FBSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
        recordMode = false
        isDeviceAgnostic = false
    }
    
    func testWorldSpeedLimitSign() {
        let rect = CGRect(x: 0, y: 0, width: 60, height: 60)
        let view = SpeedLimitSign(frame: rect)
        view.region = .world
        view.speedLimit = SpeedLimit(value: 20, speedUnits: .kilometersPerHour)
        FBSnapshotVerifyView(view)
    }
    
    func testWorldSpeedLimitSign150() {
        let rect = CGRect(x: 0, y: 0, width: 60, height: 60)
        let view = SpeedLimitSign(frame: rect)
        view.region = .world
        view.speedLimit = SpeedLimit(value: 150, speedUnits: .kilometersPerHour)
        FBSnapshotVerifyView(view)
    }
    
    func testUSSpeedLimitSign() {
        let rect = CGRect(x: 0, y: 0, width: 50, height: 80)
        let view = SpeedLimitSign(frame: rect)
        view.region = .unitedStates
        view.speedLimit = SpeedLimit(value: 20, speedUnits: .milesPerHour)
        FBSnapshotVerifyView(view)
    }
}

