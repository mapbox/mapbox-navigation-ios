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
    func didUpdatePosition(_ position: EHorizonPosition, distances: [EHorizonDistancesKey : EHorizonObjectDistanceInfo]) {
        let graphPosition = position.position
        _ = passiveLocationDataSource.graphAccessor.getEdgeMetadata(for: graphPosition.edgeId)
        _ = passiveLocationDataSource.graphAccessor.getEdgeShape(for: graphPosition.edgeId)
    }

    func didEnterObject(_ objectEnterExitInfo: EHorizonObjectEnterExitInfo) {}

    func didExitRoadObject(_ objectEnterExitInfo: EHorizonObjectEnterExitInfo) {}
}

extension EHorizonTests: RoadObjectsStoreDelegate {
    func didAddRoadObject(with id: RoadObjectId) {
        _ = passiveLocationDataSource.roadObjectsStore.getRoadObjectMetadata(for: id)
    }

    func didUpdateRoadObject(with id: RoadObjectId) {}

    func didRemoveRoadObject(with id: RoadObjectId) {}
}
