import Foundation
import MapboxNavigationNative

/**
 `RoadObjectMatcher` delegate.
 
 - note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the feature.
 */
public protocol RoadObjectMatcherDelegate: AnyObject {
    /**
     This method is called with a road object when the matching is successfully finished.
     */
    func roadObjectMatcher(_ matcher: RoadObjectMatcher, didMatch roadObject: RoadObject)

    /**
     This method is called when the matching is finished with error.
     */
    func roadObjectMatcher(_ matcher: RoadObjectMatcher, didFailToMatchWith error: RoadObjectMatcherError)
    
    /**
     This method is called when the matching is canceled.
     */
    func roadObjectMatcher(_ matcher: RoadObjectMatcher, didCancelMatchingFor id: String)
}
