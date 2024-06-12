import MapboxNavigationNative

/// Describes a road shield information.
///
/// - note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta
/// and is subject to changes, including its pricing. Use of the feature is subject to the beta product restrictions
/// in the Mapbox Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at
/// any time and require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of
/// the level of use of the feature.
public struct RoadShield: Equatable, Sendable {
    /// The base url for a shield image.
    public let baseUrl: String

    /// The shield display reference.
    public let displayRef: String

    /// The shield text.
    public let name: String

    ///  The string indicating the color of the text to be rendered on the route shield, e.g. "black".
    public let textColor: String

    /// Creates a new `Shield` instance.
    /// - Parameters:
    ///   - baseUrl: The base url for a shield image.
    ///   - displayRef: The shield display reference.
    ///   - name: The shield text.
    ///   - textColor: The string indicating the color of the text to be rendered on the route shield.
    public init(baseUrl: String, displayRef: String, name: String, textColor: String) {
        self.baseUrl = baseUrl
        self.displayRef = displayRef
        self.name = name
        self.textColor = textColor
    }

    init(_ native: MapboxNavigationNative.Shield) {
        self.baseUrl = native.baseUrl
        self.name = native.name
        self.displayRef = native.displayRef
        self.textColor = native.textColor
    }
}
