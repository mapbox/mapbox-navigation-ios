import Foundation

/// Attributes are metadata information for a route leg.
///
/// When any of the attributes are specified, the resulting route leg contains one attribute value for each segment in
/// leg, where a segment is the straight line between two coordinates in the route leg’s full geometry.
public struct AttributeOptions: CustomValueOptionSet, CustomStringConvertible, Equatable, Sendable {
    public var rawValue: Int

    public var customOptionsByRawValue: [Int: String] = [:]

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init() {
        self.rawValue = 0
    }

    /// Live-traffic closures along the road segment.
    ///
    /// When this attribute is specified, the ``RouteLeg/closures`` property is filled with relevant data.
    ///
    /// This attribute requires ``ProfileIdentifier/automobileAvoidingTraffic`` and is supported only by Directions and
    /// Map Matching requests.
    public static let closures = AttributeOptions(rawValue: 1)

    /// Distance (in meters) along the segment.
    ///
    /// When this attribute is specified, the ``RouteLeg/segmentDistances`` property contains one value for each segment
    /// in the leg’s full geometry.
    /// When used in Matrix request - will produce a distances matrix in response.
    public static let distance = AttributeOptions(rawValue: 1 << 1)

    /// Expected travel time (in seconds) along the segment.
    ///
    /// When this attribute is specified, the ``RouteLeg/expectedSegmentTravelTimes`` property contains one value for
    /// each segment in the leg’s full geometry.
    /// When used in Matrix request - will produce a durations matrix in response.
    public static let expectedTravelTime = AttributeOptions(rawValue: 1 << 2)

    /// Current average speed (in meters per second) along the segment.
    ///
    /// When this attribute is specified, the ``RouteLeg/segmentSpeeds`` property contains one value for each segment in
    /// the leg’s full geometry. This attribute is supported only by Directions and Map Matching requests.
    public static let speed = AttributeOptions(rawValue: 1 << 3)

    /// Traffic congestion level along the segment.
    ///
    /// When this attribute is specified, the ``RouteLeg/segmentCongestionLevels`` property contains one value for each
    /// segment
    /// in the leg’s full geometry.
    ///
    /// This attribute requires ``ProfileIdentifier/automobileAvoidingTraffic`` and is supported only by Directions and
    /// Map Matching requests. Any other profile identifier produces ``CongestionLevel/unknown`` for each segment along
    /// the route.
    public static let congestionLevel = AttributeOptions(rawValue: 1 << 4)

    /// The maximum speed limit along the segment.
    ///
    /// When this attribute is specified, the ``RouteLeg/segmentMaximumSpeedLimits`` property contains one value for
    /// each segment in the leg’s full geometry. This attribute is supported only by Directions and Map Matching
    /// requests.
    public static let maximumSpeedLimit = AttributeOptions(rawValue: 1 << 5)

    /// Traffic congestion level in numeric form.
    ///
    /// When this attribute is specified, the ``RouteLeg/segmentNumericCongestionLevels`` property contains one value
    /// for each
    /// segment in the leg’s full geometry.
    /// This attribute requires ``ProfileIdentifier/automobileAvoidingTraffic`` and is supported only by Directions and
    /// Map Matching requests. Any other profile identifier produces `nil` for each segment along the route.
    public static let numericCongestionLevel = AttributeOptions(rawValue: 1 << 6)

    /// The tendency value conveys the changing state of traffic congestion (increasing, decreasing, constant etc).
    public static let trafficTendency = AttributeOptions(rawValue: 1 << 7)

    /// Creates an ``AttributeOptions`` from the given description strings.
    public init?(descriptions: [String]) {
        var attributeOptions: AttributeOptions = []
        for description in descriptions {
            switch description {
            case "closure":
                attributeOptions.update(with: .closures)
            case "distance":
                attributeOptions.update(with: .distance)
            case "duration":
                attributeOptions.update(with: .expectedTravelTime)
            case "speed":
                attributeOptions.update(with: .speed)
            case "congestion":
                attributeOptions.update(with: .congestionLevel)
            case "maxspeed":
                attributeOptions.update(with: .maximumSpeedLimit)
            case "congestion_numeric":
                attributeOptions.update(with: .numericCongestionLevel)
            case "traffic_tendency":
                attributeOptions.update(with: .trafficTendency)
            case "":
                continue
            default:
                return nil
            }
        }
        self.init(rawValue: attributeOptions.rawValue)
    }

    public var description: String {
        var descriptions: [String] = []
        if contains(.closures) {
            descriptions.append("closure")
        }
        if contains(.distance) {
            descriptions.append("distance")
        }
        if contains(.expectedTravelTime) {
            descriptions.append("duration")
        }
        if contains(.speed) {
            descriptions.append("speed")
        }
        if contains(.congestionLevel) {
            descriptions.append("congestion")
        }
        if contains(.maximumSpeedLimit) {
            descriptions.append("maxspeed")
        }
        if contains(.numericCongestionLevel) {
            descriptions.append("congestion_numeric")
        }
        if contains(.trafficTendency) {
            descriptions.append("traffic_tendency")
        }
        for (key, value) in customOptionsByRawValue {
            if rawValue & key != 0 {
                descriptions.append(value)
            }
        }
        return descriptions.joined(separator: ",")
    }
}

extension AttributeOptions: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description.components(separatedBy: ",").filter { !$0.isEmpty })
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let descriptions = try container.decode([String].self)
        self = AttributeOptions(descriptions: descriptions)!
    }
}
