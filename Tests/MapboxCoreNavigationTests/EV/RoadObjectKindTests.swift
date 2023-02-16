import Foundation
import XCTest
import TestHelper
import MapboxNavigationNative
@testable import MapboxCoreNavigation

final class RoadObjectKindTests: TestCase {
    let metadataName: [LocalizedString] = [
        .init(language: "en", value: "Road"),
        .init(language: "jp", value: "京葉道路")
    ]
    let roadObjectNames: [LocalizedRoadObjectName] = [
        .init(language: "en", text: "Road"),
        .init(language: "jp", text: "京葉道路")
    ]

    func testCreatesFromMetadataIfIC() {
        let icInfo = IcInfo(name: metadataName)
        let metadata = RoadObjectMetadata.fromIcInfo(icInfo)
        let kind = RoadObject.Kind(type: .ic, metadata: metadata)

        guard case .ic(let interchange) = kind else {
            return XCTFail("Road Object kind should be IC");
        }
        XCTAssertEqual(interchange, Interchange(names: roadObjectNames))
    }

    func testCreatesFromMetadataIfNoICInfo() {
        let tollInfo = TollCollectionInfo(type: .tollBooth, name: nil)
        let metadata = RoadObjectMetadata.fromTollCollectionInfo(tollInfo)
        let kind = RoadObject.Kind(type: .ic, metadata: metadata)

        guard case .ic(let interchange) = kind else {
            return XCTFail("Road Object kind should be IC");
        }
        XCTAssertNil(interchange)
    }

    func testCreatesFromMetadataIfJCT() {
        let jctInfo = JctInfo(name: metadataName)
        let metadata = RoadObjectMetadata.fromJctInfo(jctInfo)
        let kind = RoadObject.Kind(type: .jct, metadata: metadata)

        guard case .jct(let junction) = kind else {
            return XCTFail("Road Object kind should be JCT");
        }
        XCTAssertEqual(junction, Junction(names: roadObjectNames))
    }

    func testCreatesFromMetadataIfNoJCTInfo() {
        let tollInfo = TollCollectionInfo(type: .tollBooth, name: nil)
        let metadata = RoadObjectMetadata.fromTollCollectionInfo(tollInfo)
        let kind = RoadObject.Kind(type: .jct, metadata: metadata)

        guard case .jct(let junction) = kind else {
            return XCTFail("Road Object kind should be JCT");
        }
        XCTAssertNil(junction)
    }
}
