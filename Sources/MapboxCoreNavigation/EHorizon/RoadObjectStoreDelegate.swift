import Foundation

/** `RoadObjectStore` delegate
 
     - note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the feature.
 */
public protocol RoadObjectStoreDelegate: AnyObject {
    /// This method is called when a road object with the given identifier has been added to the road objects store.
    func didAddRoadObject(identifier: RoadObject.Identifier)
    
    /// This method is called when a road object with the given identifier has been updated in the road objects store.
    func didUpdateRoadObject(identifier: RoadObject.Identifier)
    
    /// This method is called when a road object with the given identifier has been removed from the road objects store.
    func didRemoveRoadObject(identifier: RoadObject.Identifier)
}
