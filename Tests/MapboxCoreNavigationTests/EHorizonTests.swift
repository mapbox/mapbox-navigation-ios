import MapboxNavigationNative
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
        try! passiveLocationDataSource.roadObjectsStore.setObserverForOptions(self)
        passiveLocationDataSource.electronicHorizonDelegate = self
    }

    var peer: MBXPeerWrapper?
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

extension EHorizonTests: RoadObjectsStoreObserver {
    func onRoadObjectAdded(forId id: String) {
        _ = try! passiveLocationDataSource.roadObjectsStore.getRoadObjectMetadata(forRoadObjectId: id)
    }

    func onRoadObjectUpdated(forId id: String) {}

    func onRoadObjectRemoved(forId id: String) {}
}
