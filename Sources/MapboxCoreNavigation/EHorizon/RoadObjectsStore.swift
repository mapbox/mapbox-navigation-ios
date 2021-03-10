import Foundation
import MapboxNavigationNative

/// Identifies a road object in an electronic horizon.
public typealias RoadObjectIdentifier = String

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
     Returns mapping `road object identifier -> RoadObjectEdgeLocation` for all road objects
     which are lying on the edge with given identifier.
     - parameter edgeIdentifier: The identifier of the edge to query.
     */
    public func roadObjectEdgeLocations(edgeIdentifier: EHorizonEdge.Identifier) -> [RoadObjectIdentifier : EHorizonObjectEdgeLocation] {
        let objects = try! native.getForEdgeId(UInt64(edgeIdentifier))
        return Dictionary(
            uniqueKeysWithValues:objects.map { identifier, location in (identifier, EHorizonObjectEdgeLocation(location)) }
        )
    }

    /**
     Returns metadata of object with given identifier, if such object cannot be found returns null.
     NB: since road objects can be removed/added in background we should always check return value for null,
     even if we know that we have object with such identifier based on previous calls.
     - parameter roadObjectIdentifier: The identifier of the road object to query.
     */
    public func roadObjectMetadata(identifier roadObjectIdentifier: RoadObjectIdentifier) -> EHorizonObjectMetadata? {
        if let metadata = try! native.getRoadObjectMetadata(forRoadObjectId: roadObjectIdentifier) {
            return EHorizonObjectMetadata(metadata)
        }
        return nil
    }

    /**
     Returns location of object with given identifier, if such object cannot be found returns null.
     NB: since road objects can be removed/added in background we should always check return value for null,
     even if we know that we have object with such identifier based on previous calls.
     - parameter roadObjectIdentifier: The identifier of the road object to query.
     */
    public func roadObjectLocation(identifier roadObjectIdentifier: RoadObjectIdentifier) -> EHorizonObjectLocation? {
        if let location = try! native.getRoadObjectLocation(forRoadObjectId: roadObjectIdentifier) {
            return EHorizonObjectLocation(location)
        }
        return nil
    }

    /**
     Returns list of road object ids which are (partially) belong to `edgeIds`.
     - parameter edgeIds list of edge ids
     */
    public func roadObjectIdentifiers(edgeIdentifiers: [EHorizonEdge.Identifier]) -> [RoadObjectIdentifier] {
        return try! native.getRoadObjectIdsByEdgeIds(forEdgeIds: edgeIdentifiers.map(NSNumber.init))
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
        delegate?.didAddRoadObject(identifier: id)
    }

    public func onRoadObjectUpdated(forId id: String) {
        delegate?.didUpdateRoadObject(identifier: id)
    }

    public func onRoadObjectRemoved(forId id: String) {
        delegate?.didRemoveRoadObject(identifier: id)
    }
}
