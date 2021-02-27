import Foundation

public protocol RoadObjectsStoreDelegate: class {

    func didAddRoadObject(with id: RoadObjectId)

    func didUpdateRoadObject(with id: RoadObjectId)

    func didRemoveRoadObject(with id: RoadObjectId)
}
