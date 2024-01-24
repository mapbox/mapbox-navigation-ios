import XCTest
import SnapshotTesting
import MapboxDirections
import CoreLocation
import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class SpeedLimitViewSnapshotTests: TestCase {
    var speedLimitView: SpeedLimitView!

    override func setUp() {
        super.setUp()
        speedLimitView = .init(frame: CGRect(origin: .zero, size: CGSize(width: 50, height: 50)))
        speedLimitView.backgroundColor = .white
        isRecording = false

        let window = UIWindow(frame: speedLimitView.bounds)
        window.addSubview(speedLimitView)
        DayStyle().apply()
    }

    override func tearDown() {
        speedLimitView = nil
    }

    func testMUTCD() {
        speedLimitView.signStandard = .mutcd
        speedLimitView.speedLimit = .init(value: 20, unit: .milesPerHour)
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.95))
    }

    func testMUTCD_blueText() {
        speedLimitView.signStandard = .mutcd
        speedLimitView.textColor = .blue
        speedLimitView.speedLimit = .init(value: 120, unit: .milesPerHour)
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.95))
    }

    func testVienna() {
        speedLimitView.signStandard = .viennaConvention
        speedLimitView.speedLimit = .init(value: 120, unit: .kilometersPerHour)
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.95))
    }

    func testVienna_blueBorder() {
        UIView.setAnimationsEnabled(false) // disabling blink-in animation
        speedLimitView.signStandard = .viennaConvention
        speedLimitView.regulatoryBorderColor = .blue
        speedLimitView.speedLimit = .init(value: 20, unit: .kilometersPerHour)
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.95))
    }

    func testUnknownViennaSpeedLimit() {
        speedLimitView.signStandard = .viennaConvention
        speedLimitView.speedLimit = nil
        speedLimitView.shouldShowUnknownSpeedLimit = true
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.95))
    }

    func testUnknownMUTCDSpeedLimit() {
        speedLimitView.signStandard = .mutcd
        speedLimitView.speedLimit = nil
        speedLimitView.shouldShowUnknownSpeedLimit = true
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.95))
    }

    func testInfiniteVennaSpeedLimit() {
        speedLimitView.signStandard = .viennaConvention
        speedLimitView.speedLimit = .init(value: .infinity, unit: .kilometersPerHour)
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.95))
    }

    func testInfiniteMUTCDSpeedLimit() {
        speedLimitView.signStandard = .mutcd
        speedLimitView.speedLimit = .init(value: .infinity, unit: .kilometersPerHour)
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.95))
    }
}
