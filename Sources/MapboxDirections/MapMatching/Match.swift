import Foundation
import Turf

/// A ``Weight`` enum represents the weight given to a specific ``Match`` by the Directions API. The default metric is a
/// compound index called "routability", which is duration-based with additional penalties for less desirable maneuvers.
public enum Weight: Equatable, Sendable {
    case routability(value: Float)
    case other(value: Float, metric: String)

    public init(value: Float, metric: String) {
        switch metric {
        case "routability":
            self = .routability(value: value)
        default:
            self = .other(value: value, metric: metric)
        }
    }

    var metric: String {
        switch self {
        case .routability(value: _):
            return "routability"
        case .other(value: _, metric: let value):
            return value
        }
    }

    var value: Float {
        switch self {
        case .routability(value: let weight):
            return weight
        case .other(value: let weight, metric: _):
            return weight
        }
    }
}

/// A ``Match`` object defines a single route that was created from a series of points that were matched against a road
/// network.
///
/// Typically, you do not create instances of this class directly. Instead, you receive match objects when you pass a
/// ``MatchOptions`` object into the `Directions.calculate(_:completionHandler:)` method.
public struct Match: DirectionsResult {
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case confidence
        case weight
        case weightName = "weight_name"
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

    /// Initializes a match.
    /// Typically, you do not create instances of this class directly. Instead, you receive match objects when you
    /// request matches using the `Directions.calculate(_:completionHandler:)` method.
    ///
    /// - Parameters:
    ///   - legs: The legs that are traversed in order.
    ///   - shape: The matching roads or paths as a contiguous polyline.
    ///   - distance: The matched path’s cumulative distance, measured in meters.
    ///   - expectedTravelTime: The route’s expected travel time, measured in seconds.
    ///   - confidence: A number between 0 and 1 that indicates the Map Matching API’s confidence that the match is
    /// accurate. A higher confidence means the match is more likely to be accurate.
    ///   - weight: A ``Weight`` enum, which represents the weight given to a specific ``Match``.
    public init(
        legs: [RouteLeg],
        shape: LineString?,
        distance: LocationDistance,
        expectedTravelTime: TimeInterval,
        confidence: Float,
        weight: Weight
    ) {
        self.confidence = confidence
        self.weight = weight
        self.legs = legs
        self.shape = shape
        self.distance = distance
        self.expectedTravelTime = expectedTravelTime
        self.responseContainsSpeechLocale = false
    }

    /// Creates a match from a decoder.
    ///
    /// - Precondition: If the decoder is decoding JSON data from an API response, the `Decoder.userInfo` dictionary
    /// must contain a ``MatchOptions`` object in the ``Swift/CodingUserInfoKey/options`` key. If it does not, a
    /// ``DirectionsCodingError/missingOptions`` error is thrown.
    ///
    /// - Parameter decoder: The decoder of JSON-formatted API response data or a previously encoded ``Match`` object.
    public init(from decoder: Decoder) throws {
        guard let options = decoder.userInfo[.options] as? DirectionsOptions else {
            throw DirectionsCodingError.missingOptions
        }

        let container = try decoder.container(keyedBy: DirectionsCodingKey.self)
        self.legs = try Self.decodeLegs(using: container, options: options)
        self.distance = try Self.decodeDistance(using: container)
        self.expectedTravelTime = try Self.decodeExpectedTravelTime(using: container)
        self.typicalTravelTime = try Self.decodeTypicalTravelTime(using: container)
        self.shape = try Self.decodeShape(using: container)
        self.speechLocale = try Self.decodeSpeechLocale(using: container)
        self.responseContainsSpeechLocale = try Self.decodeResponseContainsSpeechLocale(using: container)

        self.confidence = try container.decode(Float.self, forKey: .match(.confidence))
        let weightValue = try container.decode(Float.self, forKey: .match(.weight))
        let weightMetric = try container.decode(String.self, forKey: .match(.weightName))

        self.weight = Weight(value: weightValue, metric: weightMetric)

        try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DirectionsCodingKey.self)
        try container.encode(confidence, forKey: .match(.confidence))
        try container.encode(weight.value, forKey: .match(.weight))
        try container.encode(weight.metric, forKey: .match(.weightName))

        try encodeLegs(into: &container)
        try encodeShape(into: &container, options: encoder.userInfo[.options] as? DirectionsOptions)
        try encodeDistance(into: &container)
        try encodeExpectedTravelTime(into: &container)
        try encodeTypicalTravelTime(into: &container)
        try encodeSpeechLocale(into: &container)

        try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
    }

    /// A ``Weight`` enum, which represents the weight given to a specific ``Match``.
    public var weight: Weight

    /// A number between 0 and 1 that indicates the Map Matching API’s confidence that the match is accurate. A higher
    /// confidence means the match is more likely to be accurate.
    public var confidence: Float
}

extension Match: CustomStringConvertible {
    public var description: String {
        return legs.map(\.name).joined(separator: " – ")
    }
}

extension DirectionsCodingKey {
    public static func match(_ key: Match.CodingKeys) -> Self {
        .init(stringValue: key.stringValue)
    }
}
