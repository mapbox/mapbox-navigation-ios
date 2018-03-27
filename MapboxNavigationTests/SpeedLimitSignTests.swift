import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation

class SpeedLimitSignTests: FBSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
        recordMode = true
        isDeviceAgnostic = true
    }
    
    func testWorldSpeedLimitSign() {
        let view: SpeedLimitSign = .forAutoLayout(hidden: false)
        view.region = .world
        view.speedLimit = SpeedLimit(value: 20, speedUnits: .kilometersPerHour)
        FBSnapshotVerifyView(view)
    }
    
    func testUSSpeedLimitSign() {
        let view: SpeedLimitSign = .forAutoLayout(hidden: false)
        view.region = .unitedStates
        view.speedLimit = SpeedLimit(value: 20, speedUnits: .milesPerHour)
        FBSnapshotVerifyView(view)
    }
}

