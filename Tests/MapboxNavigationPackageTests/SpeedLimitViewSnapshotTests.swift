import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
@testable import MapboxNavigationUIKit
import SnapshotTesting
import TestHelper
import XCTest

class SpeedLimitViewSnapshotTests: TestCase {
    var speedLimitView: SpeedLimitView!

    override func setUp() {
        super.setUp()
        speedLimitView = .init(frame: CGRect(origin: .zero, size: CGSize(width: 50, height: 50)))
        speedLimitView.backgroundColor = .white
        speedLimitView.signBackColor = .white

        let window = UIWindow(frame: speedLimitView.bounds)
        window.addSubview(speedLimitView)
        DayStyle().apply()
    }

    override func tearDown() {
        speedLimitView = nil
        super.tearDown()
    }

    func testMUTCD() {
        speedLimitView.signStandard = .mutcd
        speedLimitView.speedLimit = .init(value: 20, unit: .milesPerHour)
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.99))
    }

    func testMUTCD_blueText() {
        speedLimitView.signStandard = .mutcd
        speedLimitView.textColor = .blue
        speedLimitView.speedLimit = .init(value: 120, unit: .milesPerHour)
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.99))
    }

    func testVienna() {
        speedLimitView.signStandard = .viennaConvention
        speedLimitView.speedLimit = .init(value: 120, unit: .kilometersPerHour)
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.99))
    }

    func testVienna_blueBorder() {
        UIView.setAnimationsEnabled(false) // disabling blink-in animation
        speedLimitView.signStandard = .viennaConvention
        speedLimitView.regulatoryBorderColor = .blue
        speedLimitView.speedLimit = .init(value: 20, unit: .kilometersPerHour)
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.99))
    }

    func testUnknownViennaSpeedLimit() {
        speedLimitView.signStandard = .viennaConvention
        speedLimitView.speedLimit = nil
        speedLimitView.shouldShowUnknownSpeedLimit = true
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.99))
    }

    func testUnknownMUTCDSpeedLimit() {
        speedLimitView.signStandard = .mutcd
        speedLimitView.speedLimit = nil
        speedLimitView.shouldShowUnknownSpeedLimit = true
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.99))
    }

    func testInfiniteViennaSpeedLimit() {
        speedLimitView.signStandard = .viennaConvention
        speedLimitView.speedLimit = .init(value: .infinity, unit: .kilometersPerHour)
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.99))
    }

    func testInfiniteMUTCDSpeedLimit() {
        speedLimitView.signStandard = .mutcd
        speedLimitView.speedLimit = .init(value: .infinity, unit: .kilometersPerHour)
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.99))
    }

    func testZeroViennaSpeedLimit() {
        speedLimitView.signStandard = .viennaConvention
        speedLimitView.speedLimit = .init(value: 0, unit: .kilometersPerHour)
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.99))
    }

    func testZeroMUTCDSpeedLimit() {
        speedLimitView.signStandard = .mutcd
        speedLimitView.speedLimit = .init(value: 0, unit: .kilometersPerHour)
        assertImageSnapshot(matching: speedLimitView.layer, as: .image(precision: 0.99))
    }
}
