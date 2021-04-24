import Foundation
import MapboxNavigationNative

/**
 Identifies a road object in an electronic horizon. A road object represents a notable transition point along a road, such as a toll booth or tunnel entrance. A road object is similar to a `RouteAlert` but is more closely associated with the routing graph managed by the `RoadGraph` class.
 
 Use a `RoadObjectsStore` object to get more information about a road object with a given identifier or get the locations of road objects along `ElectronicHorizon.Edge`s.
 */
public typealias RoadObjectIdentifier = String

/**
 Stores and provides access to metadata about road objects.
 
 You do not create a `RoadObjectsStore` object manually. Instead, use the `RouteController.roadObjectsStore` or `PassiveLocationDataSource.roadObjectsStore` to access the currently active road objects store.
 */
public final class RoadObjectsStore {
    /// The road objects store’s delegate.
    public weak var delegate: RoadObjectsStoreDelegate? {
        didSet {
            if delegate != nil {
                native.setObserverForOptions(self)
            } else {
                native.setObserverForOptions(nil)
            }
        }
    }

    /**
     Returns mapping `road object identifier -> RoadObjectEdgeLocation` for all road objects
     which are lying on the edge with given identifier.
     - parameter edgeIdentifier: The identifier of the edge to query.
     */
    public func roadObjectEdgeLocations(edgeIdentifier: ElectronicHorizon.Edge.Identifier) -> [RoadObjectIdentifier : RoadObjectEdgeLocation] {
        let objects = native.getForEdgeId(UInt64(edgeIdentifier))
        return objects.mapValues(RoadObjectEdgeLocation.init)
    }

    /**
     Returns metadata of object with given identifier, if such object cannot be found returns null.
     NB: since road objects can be removed/added in background we should always check return value for null,
     even if we know that we have object with such identifier based on previous calls.
     - parameter roadObjectIdentifier: The identifier of the road object to query.
     */
    public func roadObjectMetadata(identifier roadObjectIdentifier: RoadObjectIdentifier) -> RoadObjectMetadata? {
        if let metadata = native.getRoadObjectMetadata(forRoadObjectId: roadObjectIdentifier) {
            return RoadObjectMetadata(metadata)
        }
        return nil
    }

    /**
     Returns location of object with given identifier, if such object cannot be found returns null.
     NB: since road objects can be removed/added in background we should always check return value for null,
     even if we know that we have object with such identifier based on previous calls.
     - parameter roadObjectIdentifier: The identifier of the road object to query.
     */
    public func roadObjectLocation(identifier roadObjectIdentifier: RoadObjectIdentifier) -> RoadObjectLocation? {
        if let location = native.getRoadObjectLocation(forRoadObjectId: roadObjectIdentifier) {
            return RoadObjectLocation(location)
        }
        return nil
    }

    /**
     Returns list of road object ids which are (partially) belong to `edgeIds`.
     - parameter edgeIds list of edge ids
     */
    public func roadObjectIdentifiers(edgeIdentifiers: [ElectronicHorizon.Edge.Identifier]) -> [RoadObjectIdentifier] {
        return native.getRoadObjectIdsByEdgeIds(forEdgeIds: edgeIdentifiers.map(NSNumber.init))
    }

    init(_ native: MapboxNavigationNative.RoadObjectsStore) {
        self.native = native
    }

    deinit {
        native.setObserverForOptions(nil)
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
