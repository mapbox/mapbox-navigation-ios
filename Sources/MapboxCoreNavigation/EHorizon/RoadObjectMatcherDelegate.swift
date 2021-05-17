import Foundation
import MapboxNavigationNative

/**
 `RoadObjectMatcher` delegate.
 */
public protocol RoadObjectMatcherDelegate: AnyObject {
    /**
     This method is called when the matching is finished.
     - parameter result: Result of road object matching,
     which is represented as an instance of `RoadObject` if the matching was successful,
     and as an instance of `RoadObjectMatcherError` otherwise.
     */
    func didMatchRoadObject(result: Result<RoadObject, RoadObjectMatcherError>)
}
