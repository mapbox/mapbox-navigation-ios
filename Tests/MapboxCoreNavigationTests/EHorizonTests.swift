@testable import MapboxCoreNavigation
import XCTest

// Happy path repeating EH General Usage Example
class EHorizonTests: XCTestCase {
    var passiveLocationDataSource: PassiveLocationDataSource!

    override func setUp() {
        super.setUp()
        passiveLocationDataSource = PassiveLocationDataSource()
    }

    override func tearDown() {
        passiveLocationDataSource = nil
        super.tearDown()
    }

    func testFreeDriveEHorizon() {
        passiveLocationDataSource.roadObjectsStore.delegate = self
        passiveLocationDataSource.electronicHorizonDelegate = self
    }
}

extension EHorizonTests: EHorizonDelegate {
    func didUpdatePosition(_ position: EHorizonPosition, distances: [RoadObjectIdentifier : EHorizonObjectDistanceInfo]) {
        let graphPosition = position.position
        _ = passiveLocationDataSource.graphAccessor.edgeMetadata(edgeIdentifier: graphPosition.edgeIdentifier)
        _ = passiveLocationDataSource.graphAccessor.edgeShape(edgeIdentifier: graphPosition.edgeIdentifier)
    }

    func didEnterObject(_ objectEnterExitInfo: EHorizonObjectEnterExitInfo) {}

    func didExitRoadObject(_ objectEnterExitInfo: EHorizonObjectEnterExitInfo) {}
}

extension EHorizonTests: RoadObjectsStoreDelegate {
    func didAddRoadObject(identifier id: RoadObjectIdentifier) {
        _ = passiveLocationDataSource.roadObjectsStore.roadObjectMetadata(identifier: id)
    }

    func didUpdateRoadObject(identifier id: RoadObjectIdentifier) {}

    func didRemoveRoadObject(identifier id: RoadObjectIdentifier) {}
}
