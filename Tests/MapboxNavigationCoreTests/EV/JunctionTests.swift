import Foundation
@testable import MapboxNavigationCore
import MapboxNavigationNative
import XCTest

final class JunctionTests: XCTestCase {
    func testCreatesFromNNInfo() {
        let identifier = "testId"
        let names: [LocalizedString] = [
            .init(language: "en", value: "Road"),
            .init(language: "jp", value: "京葉道路"),
        ]
        let info = JctInfo(id: identifier, name: names)

        let expectedNames: [LocalizedRoadObjectName] = [
            .init(language: "en", text: "Road"),
            .init(language: "jp", text: "京葉道路"),
        ]
        let expected = Junction(identifier: identifier, names: expectedNames)
        XCTAssertEqual(Junction(info), expected)
    }
}
