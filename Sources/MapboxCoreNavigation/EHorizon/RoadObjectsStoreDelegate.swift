import Foundation

public protocol RoadObjectsStoreDelegate: class {

    func didAddRoadObject(identifier: RoadObjectIdentifier)

    func didUpdateRoadObject(identifier: RoadObjectIdentifier)

    func didRemoveRoadObject(identifier: RoadObjectIdentifier)
}
