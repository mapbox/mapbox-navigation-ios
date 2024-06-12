import Foundation
import MapboxNavigationNative

/// An error that occures during road object matching.
///
/// - Note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to
/// changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms
/// of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require
/// customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the
/// feature.
public struct RoadObjectMatcherError: LocalizedError {
    /// Description of the error.
    public let description: String

    /// Identifier of the road object for which matching is failed.
    public let roadObjectIdentifier: RoadObject.Identifier

    /// Description of the error.
    public var errorDescription: String? {
        return description
    }

    /// Initializes a new ``RoadObjectMatcherError``.
    /// - Parameters:
    ///   - description: Description of the error.
    ///   - roadObjectIdentifier: Identifier of the road object for which matching is failed.
    public init(description: String, roadObjectIdentifier: RoadObject.Identifier) {
        self.description = description
        self.roadObjectIdentifier = roadObjectIdentifier
    }

    init(_ native: MapboxNavigationNative.RoadObjectMatcherError) {
        self.description = native.description
        self.roadObjectIdentifier = native.roadObjectId
    }
}
