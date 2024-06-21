import Foundation
import Turf

/// A ``Route`` object defines a single route that the user can follow to visit a series of waypoints in order. The
/// route object includes information about the route, such as its distance and expected travel time. Depending on the
/// criteria used to calculate the route, the route object may also include detailed turn-by-turn instructions.
///
/// Typically, you do not create instances of this class directly. Instead, you receive route objects when you request
/// directions using the `Directions.calculate(_:completionHandler:)` or
/// `Directions.calculateRoutes(matching:completionHandler:)` method. However, if you use the
/// `Directions.url(forCalculating:)` method instead, you can use `JSONDecoder` to convert the HTTP response into a
/// ``RouteResponse`` or ``MapMatchingResponse`` object and access the ``RouteResponse/routes`` or
/// ``MapMatchingResponse/matches`` property.
public struct Route: DirectionsResult {
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case tollPrices = "toll_costs"
    }

    public var shape: Turf.LineString?

    public var legs: [RouteLeg]

    public var distance: Turf.LocationDistance

    public var expectedTravelTime: TimeInterval

    public var typicalTravelTime: TimeInterval?

    public var speechLocale: Locale?

    public var fetchStartDate: Date?

    public var responseEndDate: Date?

    public var responseContainsSpeechLocale: Bool

    public var foreignMembers: Turf.JSONObject = [:]

    /// Initializes a route.
    /// - Parameters:
    ///   - legs: The legs that are traversed in order.
    ///   - shape: The roads or paths taken as a contiguous polyline.
    ///   - distance: The route’s distance, measured in meters.
    ///   - expectedTravelTime: The route’s expected travel time, measured in seconds.
    ///   - typicalTravelTime: The route’s typical travel time, measured in seconds.
    public init(
        legs: [RouteLeg],
        shape: LineString?,
        distance: LocationDistance,
        expectedTravelTime: TimeInterval,
        typicalTravelTime: TimeInterval? = nil
    ) {
        self.legs = legs
        self.shape = shape
        self.distance = distance
        self.expectedTravelTime = expectedTravelTime
        self.typicalTravelTime = typicalTravelTime
        self.responseContainsSpeechLocale = false
    }

    /// Initializes a route from a decoder.
    ///
    /// - Precondition: If the decoder is decoding JSON data from an API response, the `Decoder.userInfo` dictionary
    /// must contain a ``RouteOptions`` or ``MatchOptions`` object in the ``Swift/CodingUserInfoKey/options`` key. If it
    /// does not, a ``DirectionsCodingError/missingOptions`` error is thrown.
    /// - Parameter decoder: The decoder of JSON-formatted API response data or a previously encoded ``Route`` object.
    public init(from decoder: Decoder) throws {
        guard let options = decoder.userInfo[.options] as? DirectionsOptions else {
            throw DirectionsCodingError.missingOptions
        }

        let container = try decoder.container(keyedBy: DirectionsCodingKey.self)
        self.tollPrices = try container.decodeIfPresent([TollPriceCoder].self, forKey: .route(.tollPrices))?
            .reduce(into: []) { $0.append(contentsOf: $1.tollPrices) }
        self.legs = try Self.decodeLegs(using: container, options: options)
        self.distance = try Self.decodeDistance(using: container)
        self.expectedTravelTime = try Self.decodeExpectedTravelTime(using: container)
        self.typicalTravelTime = try Self.decodeTypicalTravelTime(using: container)
        self.shape = try Self.decodeShape(using: container)
        self.speechLocale = try Self.decodeSpeechLocale(using: container)
        self.responseContainsSpeechLocale = try Self.decodeResponseContainsSpeechLocale(using: container)

        try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DirectionsCodingKey.self)
        try container.encodeIfPresent(tollPrices.map { TollPriceCoder(tollPrices: $0) }, forKey: .route(.tollPrices))

        try encodeLegs(into: &container)
        try encodeShape(into: &container, options: encoder.userInfo[.options] as? DirectionsOptions)
        try encodeDistance(into: &container)
        try encodeExpectedTravelTime(into: &container)
        try encodeTypicalTravelTime(into: &container)
        try encodeSpeechLocale(into: &container)

        try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
    }

    /// List of calculated toll costs for this route.
    ///
    /// This property is set to `nil` unless request ``RouteOptions/includesTollPrices`` is set to `true`.
    public var tollPrices: [TollPrice]?
}

extension Route: CustomStringConvertible {
    public var description: String {
        return legs.map(\.name).joined(separator: " – ")
    }
}

extension DirectionsCodingKey {
    static func route(_ key: Route.CodingKeys) -> Self {
        .init(stringValue: key.rawValue)
    }
}

extension Route: Equatable {
    public static func == (lhs: Route, rhs: Route) -> Bool {
        return lhs.distance == rhs.distance &&
            lhs.expectedTravelTime == rhs.expectedTravelTime &&
            lhs.typicalTravelTime == rhs.typicalTravelTime &&
            lhs.speechLocale == rhs.speechLocale &&
            lhs.responseContainsSpeechLocale == rhs.responseContainsSpeechLocale &&
            lhs.legs == rhs.legs &&
            lhs.shape == rhs.shape &&
            lhs.tollPrices.map { Set($0) } == rhs.tollPrices
            .map { Set($0) } // comparing sets to mitigate items reordering caused by custom Coding impl.
    }
}
