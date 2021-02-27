import Foundation
import MapboxNavigationNative

public typealias RoadObjectId = String

public class RoadObjectsStore {

    public weak var delegate: RoadObjectsStoreDelegate? {
        didSet {
            if delegate != nil {
                try! native.setObserverForOptions(self)
            } else {
                try! native.setObserverForOptions(nil)
            }
        }
    }

    /**
     Returns mapping `road object id -> RoadObjectEdgeLocation` for all road objects
     which are lying on the edge with given id.
     - parameter edgeId
     */
    public func getRoadObjects(for edgeId: UInt) -> [RoadObjectId : EHorizonObjectEdgeLocation] {
        let objects = try! native.getForEdgeId(UInt64(edgeId))
        return Dictionary(
            uniqueKeysWithValues:objects.map { id, location in (id, EHorizonObjectEdgeLocation(location)) }
        )
    }

    /**
     Returns metadata of object with given id, if such object cannot be found returns null.
     NB: since road objects can be removed/added in background we should always check return value for null,
     even if we know that we have object with such id based on previous calls.
     - parameter roadObjectId
     */
    public func getRoadObjectMetadata(for roadObjectId: RoadObjectId) -> EHorizonObjectMetadata? {
        if let metadata = try! native.getRoadObjectMetadata(forRoadObjectId: roadObjectId) {
            return EHorizonObjectMetadata(metadata)
        }
        return nil
    }

    /**
     Returns location of object with given id, if such object cannot be found returns null.
     NB: since road objects can be removed/added in background we should always check return value for null,
     even if we know that we have object with such id based on previous calls.
     - parameter roadObjectId
     */
    public func getRoadObjectLocation(for roadObjectId: RoadObjectId) -> EHorizonObjectLocation? {
        if let location = try! native.getRoadObjectLocation(forRoadObjectId: roadObjectId) {
            return EHorizonObjectLocation(location)
        }
        return nil
    }

    /**
     Returns list of road object ids which are (partially) belong to `edgeIds`.
     - parameter edgeIds list of edge ids
     */
    public func getRoadObjectIdsByEdgeIds(forEdgeIds edgeIds: [UInt]) -> [RoadObjectId] {
        return try! native.getRoadObjectIdsByEdgeIds(forEdgeIds: edgeIds.map(NSNumber.init))
    }

    /**
     Adds road object to be tracked in electronic horizon. In case if object with such id already exists updates it.
     - parameter roadObjectId unique id of object
     - parameter location road object location (can be obtained using OpenLRDecoder)
     */
    public func addCustomRoadObject(for roadObjectId: RoadObjectId, location: OpenLRLocation) {
//        native.addCustomRoadObject(forId: roadObjectId, location: <#T##OpenLRLocation#>)
    }

    /**
     Removes road object(i.e. stops tracking it in electronic horizon)
     - parameter roadObjectId of road object
     */
    public func removeCustomRoadObject(for roadObjectId: RoadObjectId) {
        try! native.removeCustomRoadObject(forId: roadObjectId)
    }

    public var peer: MBXPeerWrapper?

    init(_ native: MapboxNavigationNative.RoadObjectsStore) {
        self.native = native
    }

    deinit {
        try! native.setObserverForOptions(nil)
    }

    private let native: MapboxNavigationNative.RoadObjectsStore
}

extension RoadObjectsStore: RoadObjectsStoreObserver {
    public func onRoadObjectAdded(forId id: String) {
        delegate?.didAddRoadObject(with: id)
    }

    public func onRoadObjectUpdated(forId id: String) {
        delegate?.didUpdateRoadObject(with: id)
    }

    public func onRoadObjectRemoved(forId id: String) {
        delegate?.didRemoveRoadObject(with: id)
    }
}
