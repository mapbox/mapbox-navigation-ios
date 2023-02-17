import Foundation
import XCTest
import TestHelper
import MapboxNavigationNative
@testable import MapboxCoreNavigation

final class JunctionTests: TestCase {
    func testCreatesFromNNInfo() {
        let names: [LocalizedString] = [
            .init(language: "en", value: "Road"),
            .init(language: "jp", value: "京葉道路")
        ]
        let info = JctInfo(name: names)

        let expectedNames: [LocalizedRoadObjectName] = [
            .init(language: "en", text: "Road"),
            .init(language: "jp", text: "京葉道路")
        ]
        let expected = Junction(names: expectedNames)
        XCTAssertEqual(Junction(info), expected)
    }

}
