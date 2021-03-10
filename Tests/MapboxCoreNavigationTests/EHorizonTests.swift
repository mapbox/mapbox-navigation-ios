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

extension EHorizonTests: ElectronicHorizonDelegate {
    func didUpdatePosition(_ position: ElectronicHorizon.Position, distances: [RoadObjectIdentifier : RoadObjectDistanceInfo]) {
        let graphPosition = position.position
        _ = passiveLocationDataSource.roadGraph.edgeMetadata(edgeIdentifier: graphPosition.edgeIdentifier)
        _ = passiveLocationDataSource.roadGraph.edgeShape(edgeIdentifier: graphPosition.edgeIdentifier)
    }

    func didEnterRoadObject(_ objectEnterExitInfo: RoadObjectTransition) {}

    func didExitRoadObject(_ objectEnterExitInfo: RoadObjectTransition) {}
}

extension EHorizonTests: RoadObjectsStoreDelegate {
    func didAddRoadObject(identifier id: RoadObjectIdentifier) {
        _ = passiveLocationDataSource.roadObjectsStore.roadObjectMetadata(identifier: id)
    }

    func didUpdateRoadObject(identifier id: RoadObjectIdentifier) {}

    func didRemoveRoadObject(identifier id: RoadObjectIdentifier) {}
}
