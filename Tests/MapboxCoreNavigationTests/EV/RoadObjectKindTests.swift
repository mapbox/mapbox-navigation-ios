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
    let identifier = "testId"

    func testCreateFromMetadataIfIC() {
        let icInfo = IcInfo(id: identifier, name: metadataName)
        let metadata = RoadObjectMetadata.fromIcInfo(icInfo)
        let kind = RoadObject.Kind(type: .ic, metadata: metadata)

        guard case .ic(let interchange) = kind else {
            return XCTFail("Road Object kind should be IC");
        }
        XCTAssertEqual(interchange, Interchange(identifier: identifier, names: roadObjectNames))
    }

    func testCreateFromMetadataIfNoICInfo() {
        let tollInfo = TollCollectionInfo(id: identifier, type: .tollBooth, name: nil)
        let metadata = RoadObjectMetadata.fromTollCollectionInfo(tollInfo)
        let kind = RoadObject.Kind(type: .ic, metadata: metadata)

        guard case .ic(let interchange) = kind else {
            return XCTFail("Road Object kind should be IC");
        }
        XCTAssertNil(interchange)
    }

    func testCreateFromMetadataIfJCT() {
        let jctInfo = JctInfo(id: identifier, name: metadataName)
        let metadata = RoadObjectMetadata.fromJctInfo(jctInfo)
        let kind = RoadObject.Kind(type: .jct, metadata: metadata)

        guard case .jct(let junction) = kind else {
            return XCTFail("Road Object kind should be JCT");
        }
        XCTAssertEqual(junction, Junction(identifier: identifier, names: roadObjectNames))
    }

    func testCreateFromMetadataIfNoJCTInfo() {
        let tollInfo = TollCollectionInfo(id: identifier, type: .tollBooth, name: nil)
        let metadata = RoadObjectMetadata.fromTollCollectionInfo(tollInfo)
        let kind = RoadObject.Kind(type: .jct, metadata: metadata)

        guard case .jct(let junction) = kind else {
            return XCTFail("Road Object kind should be JCT");
        }
        XCTAssertNil(junction)
    }

    func testCreateNotificationType() {
        let notificationInfo = NotificationInfo(id: "id",
                                                type: "type",
                                                subType: "subtype",
                                                geometryIndexStart: nil,
                                                geometryIndexEnd: nil,
                                                details: nil)
        let metadata = RoadObjectMetadata.fromNotificationInfo(notificationInfo)
        let kind = RoadObject.Kind(type: .notification, metadata: metadata)
        guard case .notification = kind else {
            return XCTFail("Road Object kind should be notification");
        }
    }

    func testCreateMergingAreaType() {
        let mergingAreaInfo = MergingAreaInfo(id: "id", merge: .fromBoth)
        let metadata = RoadObjectMetadata.fromMergingAreaInfo(mergingAreaInfo)
        let kind = RoadObject.Kind(type: .mergingArea, metadata: metadata)
        guard case .mergingArea = kind else {
            return XCTFail("Road Object kind should be mergingArea");
        }
    }
}
