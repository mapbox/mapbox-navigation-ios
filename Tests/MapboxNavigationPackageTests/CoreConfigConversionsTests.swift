import MapboxNavigationCore
@testable import MapboxNavigationUIKit
import TestHelper
import XCTest

final class CoreConfigConversionsTests: TestCase {
    func testDistanceMeasurementSystem() {
        var coreConfig = CoreConfig()

        coreConfig.unitOfMeasurement = .imperial
        XCTAssertEqual(coreConfig.distanceMeasurementSystem, .imperial)

        coreConfig.unitOfMeasurement = .metric
        XCTAssertEqual(coreConfig.distanceMeasurementSystem, .metric)

        coreConfig.locale = Locale(identifier: "en_US")
        coreConfig.unitOfMeasurement = .auto
        XCTAssertEqual(coreConfig.distanceMeasurementSystem, .imperial)

        coreConfig.locale = Locale(identifier: "pl_PL")
        coreConfig.unitOfMeasurement = .auto
        XCTAssertEqual(coreConfig.distanceMeasurementSystem, .metric)
    }
}
