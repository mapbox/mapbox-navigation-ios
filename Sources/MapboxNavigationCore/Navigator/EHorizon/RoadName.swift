import Foundation
import MapboxNavigationNative

/// Road information, like Route number, street name, shield information, etc.
///
/// - note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta
/// and is subject to changes, including its pricing. Use of the feature is subject to the beta product restrictions
/// in the Mapbox Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at
/// any time and require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of
/// the level of use of the feature.
public struct RoadName: Equatable, Sendable {
    /// The name of the road.
    ///
    /// If you display a name to the user, you may need to abbreviate common words like “East” or “Boulevard” to ensure
    /// that it fits in the allotted space.
    public let text: String

    /// IETF BCP 47 language tag or "Unspecified" or empty string.
    public let language: String

    /// Shield information of the road.
    public let shield: RoadShield?

    /// Creates a new `RoadName` instance.
    /// - Parameters:
    ///   - text: The name of the road.
    ///   - language: IETF BCP 47 language tag or "Unspecified" or empty string.
    ///   - shield: Shield information of the road.
    public init(text: String, language: String, shield: RoadShield? = nil) {
        self.text = text
        self.language = language
        self.shield = shield
    }

    init?(_ native: MapboxNavigationNative.RoadName) {
        guard native.text != "/" else { return nil }

        self.shield = native.shield.map(RoadShield.init)
        self.text = native.text
        self.language = native.language
    }
}
