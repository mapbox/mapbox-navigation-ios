@testable import MapboxNavigationCore
import XCTest

final class LocaleTests: XCTestCase {
    func testFallbackDistanceUnit() throws {
        XCTAssertEqual(Locale(identifier: "en-US").fallbackDistanceUnit, .mile)
        XCTAssertEqual(Locale(identifier: "en-US").fallbackDistanceUnit, .mile)
        XCTAssertEqual(Locale(identifier: "pl_PL").fallbackDistanceUnit, .kilometer)
    }

    @available(iOS 16.0, *)
    func testCalculatedDistanceUnitIOS16() throws {
        XCTAssertEqual(Locale(identifier: "en-US").calculatedDistanceUnit, .mile)
        XCTAssertEqual(Locale(identifier: "en-US").calculatedDistanceUnit, .mile)
        XCTAssertEqual(Locale(identifier: "pl_PL").calculatedDistanceUnit, .kilometer)
    }
}
