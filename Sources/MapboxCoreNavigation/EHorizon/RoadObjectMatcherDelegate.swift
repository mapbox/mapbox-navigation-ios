import Foundation
import MapboxNavigationNative

/**
 `RoadObjectMatcher` delegate.
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
