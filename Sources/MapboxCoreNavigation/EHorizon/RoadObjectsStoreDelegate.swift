import Foundation

/** `RoadObjectsStore` delegate */
public protocol RoadObjectsStoreDelegate: class {
    /// This method is called when a road object with the given identifier has been added to the road objects store.
    func didAddRoadObject(identifier: RoadObjectIdentifier)
    
    /// This method is called when a road object with the given identifier has been updated in the road objects store.
    func didUpdateRoadObject(identifier: RoadObjectIdentifier)
    
    /// This method is called when a road object with the given identifier has been removed from the road objects store.
    func didRemoveRoadObject(identifier: RoadObjectIdentifier)
}
