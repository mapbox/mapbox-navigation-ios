import MapboxNavigationNative
@testable import MapboxCoreNavigation
import XCTest

// Happy path repeating EH General Usage Example
// https://github.com/mapbox/mapbox-navigation-native/blob/0e5ec2b339a129aa67138a4f2cb25a47d909a611/docs/eh_integration.md#general-usage-example
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

extension EHorizonTests: ElectronicHorizonDelegate {
    func didUpdatePosition(_ position: ElectronicHorizonPosition, distances: [String : RoadObjectDistanceInfo]) {
        let graphPosition = try! position.position()
        _ = try! Navigator.shared.graphAccessor.getEdgeMetadata(forEdgeId: graphPosition.edgeId)
        _ = try! Navigator.shared.graphAccessor.getEdgeShape(forEdgeId: graphPosition.edgeId)
    }

    func roadObjectDidEnter(_ objectEnterExitInfo: RoadObjectEnterExitInfo) {}

    func roadObjectDidExit(_ objectEnterExitInfo: RoadObjectEnterExitInfo) {}
}

extension EHorizonTests: RoadObjectsStoreObserver {
    func onRoadObjectAdded(forId id: String) {
        _ = try! passiveLocationDataSource.roadObjectsStore.getRoadObjectMetadata(forRoadObjectId: id)
    }

    func onRoadObjectUpdated(forId id: String) {}

    func onRoadObjectRemoved(forId id: String) {}
}
