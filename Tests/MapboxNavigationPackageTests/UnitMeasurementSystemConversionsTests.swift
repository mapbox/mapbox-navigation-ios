import MapboxDirections
import MapboxNavigationCore
@testable import MapboxNavigationUIKit
import TestHelper
import XCTest

final class UnitMeasurementSystemConversionsTests: TestCase {
    func testVoiceUnits() {
        XCTAssertEqual(Locale(identifier: "en_US").unitMeasurementSystem, .imperial)
        XCTAssertEqual(Locale(identifier: "en_GB").unitMeasurementSystem, .britishImperial)
        XCTAssertEqual(Locale(identifier: "pl_PL").unitMeasurementSystem, .metric)
        XCTAssertEqual(Locale(identifier: "Unknown").unitMeasurementSystem, .metric)
    }
}
