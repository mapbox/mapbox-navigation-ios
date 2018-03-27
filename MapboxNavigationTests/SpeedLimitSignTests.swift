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
        view.clipsToBounds = true
        view.layer.borderWidth = 1.0 / UIScreen.main.scale
        view.region = .world
        view.speedLimit = SpeedLimit(value: 20, speedUnits: .kilometersPerHour)
        FBSnapshotVerifyView(view)
    }
}

