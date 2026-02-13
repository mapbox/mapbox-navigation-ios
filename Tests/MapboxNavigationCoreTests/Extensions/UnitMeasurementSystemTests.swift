import MapboxDirections
@testable import MapboxNavigationCore
import XCTest

final class UnitMeasurementSystemTests: XCTestCase {
    func testConversionFromLengthUnit() {
        let expectedConversions: [LengthFormatter.Unit: UnitMeasurementSystem] = [
            .kilometer: .metric,
            .centimeter: .metric,
            .meter: .metric,
            .millimeter: .metric,
            .foot: .imperial,
            .inch: .imperial,
            .mile: .imperial,
            .yard: .britishImperial,
        ]

        var actualConversions: [LengthFormatter.Unit: UnitMeasurementSystem] = [:]
        for lengthUnit in expectedConversions.keys {
            actualConversions[lengthUnit] = .init(lengthUnit)
        }

        XCTAssertEqual(actualConversions, expectedConversions)
    }
}
