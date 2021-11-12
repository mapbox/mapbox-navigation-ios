import Foundation
import TestHelper
import MapboxCoreNavigation
import MapboxDirections
import XCTest

final class MeasurementSystemTests: TestCase {
    func testConversionFromLengthUnit() {
        let expectedConversions: [LengthFormatter.Unit: MeasurementSystem] = [
            .kilometer: .metric,
            .centimeter: .metric,
            .meter: .metric,
            .millimeter: .metric,
            .foot: .imperial,
            .inch: .imperial,
            .mile: .imperial,
            .yard: .imperial,
        ]

        var actualConversions: [LengthFormatter.Unit: MeasurementSystem] = [:]
        for lengthUnit in expectedConversions.keys {
            actualConversions[lengthUnit] = .init(lengthUnit)
        }

        XCTAssertEqual(actualConversions, expectedConversions)
    }

    func testConversionToLengthUnit() {
        let expectedConversions: [MeasurementSystem: LengthFormatter.Unit] = [
            .metric: .kilometer,
            .imperial: .mile,
        ]

        var actualConversions: [MeasurementSystem: LengthFormatter.Unit] = [:]
        for measurementSystem in expectedConversions.keys {
            actualConversions[measurementSystem] = .init(measurementSystem)
        }

        XCTAssertEqual(actualConversions, expectedConversions)
    }
}
