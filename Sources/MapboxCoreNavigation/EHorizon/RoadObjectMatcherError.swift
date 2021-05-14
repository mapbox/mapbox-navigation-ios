import Foundation
import MapboxNavigationNative

/**
 An error that occures during road object matching.
 */
public struct RoadObjectMatcherError: Error {

    /** Description of the error. */
    public let description: String

    /** Identifier of the road object for which matching is failed. */
    public let roadObjectIdentifier: RoadObjectIdentifier

    /**
     Initializes a new `RoadObjectMatcherError`.
     - parameter description: Description of the error.
     - parameter roadObjectIdentifier: Identifier of the road object for which matching is failed.
     */
    public init(description: String, roadObjectIdentifier: RoadObjectIdentifier) {
        self.description = description
        self.roadObjectIdentifier = roadObjectIdentifier
    }

    init(_ native: MapboxNavigationNative.RoadObjectMatcherError) {
        description = native.description
        roadObjectIdentifier = native.roadObjectId
    }
}
