import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation

class SpeedLimitSignTests: FBSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
        recordMode = false
        isDeviceAgnostic = true
    }
    
    func testWorldSpeedLimitSign() {
        let rect = CGRect(x: 0, y: 0, width: 80, height: 80)
        let view = SpeedLimitSign(frame: rect)
        view.region = .world
        view.speedLimit = SpeedLimit(value: 20, speedUnits: .kilometersPerHour)
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

