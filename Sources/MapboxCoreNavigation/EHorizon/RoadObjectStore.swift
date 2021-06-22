import Foundation
import MapboxNavigationNative

/**
 Identifies a road object in an electronic horizon. A road object represents a notable transition point along a road, such as a toll booth or tunnel entrance. A road object is similar to a `RouteAlert` but is more closely associated with the routing graph managed by the `RoadGraph` class.
 
 Use a `RoadObjectStore` object to get more information about a road object with a given identifier or get the locations of road objects along `RoadGraph.Edge`s.
 */
public typealias RoadObjectIdentifier = String

/**
 Stores and provides access to metadata about road objects.
 
 You do not create a `RoadObjectStore` object manually. Instead, use the `RouteController.roadObjectStore` or `PassiveLocationManager.roadObjectStore` to access the currently active road object store.
 */
public final class RoadObjectStore {
    /// The road object store’s delegate.
    public weak var delegate: RoadObjectStoreDelegate? {
        didSet {
            updateObserver()
        }
    }

    /**
     Returns mapping `road object identifier -> RoadObjectEdgeLocation` for all road objects
     which are lying on the edge with given identifier.
     - parameter edgeIdentifier: The identifier of the edge to query.
     */
    public func roadObjectEdgeLocations(edgeIdentifier: RoadGraph.Edge.Identifier) -> [RoadObjectIdentifier : RoadObjectEdgeLocation] {
        let objects = native.getForEdgeId(UInt64(edgeIdentifier))
        return objects.mapValues(RoadObjectEdgeLocation.init)
    }

    /**
     Returns road object with given identifier, if such object cannot be found returns null.
     NB: since road objects can be removed/added in background we should always check return value for null,
     even if we know that we have object with such identifier based on previous calls.
     - parameter roadObjectIdentifier: The identifier of the road object to query.
     */
    public func roadObject(identifier roadObjectIdentifier: RoadObjectIdentifier) -> RoadObject? {
        if let roadObject = native.getRoadObject(forId: roadObjectIdentifier) {
            return RoadObject(roadObject)
        }
        return nil
    }

    /**
     Returns list of road object ids which are (partially) belong to `edgeIds`.
     - parameter edgeIds list of edge ids
     */
    public func roadObjectIdentifiers(edgeIdentifiers: [RoadGraph.Edge.Identifier]) -> [RoadObjectIdentifier] {
        return native.getRoadObjectIdsByEdgeIds(forEdgeIds: edgeIdentifiers.map(NSNumber.init))
    }

    /**
     Adds a road object to be tracked in the electronic horizon. In case if an object with such identifier already exists, updates it.
     NB: a road object obtained from route alerts cannot be added via this API.

     - parameter roadObject: Custom road object, acquired from `RoadObjectMatcher`.
     */
    public func addUserDefinedRoadObject(_ roadObject: RoadObject) {
        guard let nativeObject = roadObject.native else {
            preconditionFailure("You can only add matched a custom road object, acquired from RoadObjectMatcher.")
        }
        native.addCustomRoadObject(for: nativeObject)
    }

    /**
     Removes road object and stops tracking it in the electronic horizon.

     - parameter identifier: Identifier of the road object that should be removed.
     */
    public func removeUserDefinedRoadObject(identifier: RoadObjectIdentifier) {
        native.removeCustomRoadObject(forId: identifier)
    }

    /**
     Removes all user-defined road objects from the store and stops tracking them in the electronic horizon.
     */
    public func removeAllUserDefinedRoadObjects() {
        native.removeAllCustomRoadObjects()
    }

    init(_ native: MapboxNavigationNative.RoadObjectsStore) {
        self.native = native
    }

    deinit {
        native.setObserverForOptions(nil)
    }

    var native: MapboxNavigationNative.RoadObjectsStore {
        didSet {
            updateObserver()
        }
    }
    
    private func updateObserver() {
        if delegate != nil {
            native.setObserverForOptions(self)
        } else {
            native.setObserverForOptions(nil)
        }
    }
}

extension RoadObjectStore: RoadObjectsStoreObserver {
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
