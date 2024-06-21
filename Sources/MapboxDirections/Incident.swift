import Foundation
import Turf

/// `Incident` describes any corresponding event, used for annotating the route.
public struct Incident: Codable, Equatable, ForeignMemberContainer, Sendable {
    public var foreignMembers: JSONObject = [:]
    public var congestionForeignMembers: JSONObject = [:]

    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case type
        case description
        case creationDate = "creation_time"
        case startDate = "start_time"
        case endDate = "end_time"
        case impact
        case subtype = "sub_type"
        case subtypeDescription = "sub_type_description"
        case alertCodes = "alertc_codes"
        case lanesBlocked = "lanes_blocked"
        case geometryIndexStart = "geometry_index_start"
        case geometryIndexEnd = "geometry_index_end"
        case countryCodeAlpha3 = "iso_3166_1_alpha3"
        case countryCode = "iso_3166_1_alpha2"
        case roadIsClosed = "closed"
        case longDescription = "long_description"
        case numberOfBlockedLanes = "num_lanes_blocked"
        case congestionLevel = "congestion"
        case affectedRoadNames = "affected_road_names"
    }

    /// Defines known types of incidents.
    ///
    /// Each incident may or may not have specific set of data, depending on it's `kind`
    public enum Kind: String, Sendable {
        /// Accident
        case accident
        /// Congestion
        case congestion
        /// Construction
        case construction
        /// Disabled vehicle
        case disabledVehicle = "disabled_vehicle"
        /// Lane restriction
        case laneRestriction = "lane_restriction"
        /// Mass transit
        case massTransit = "mass_transit"
        /// Miscellaneous
        case miscellaneous
        /// Other news
        case otherNews = "other_news"
        /// Planned event
        case plannedEvent = "planned_event"
        /// Road closure
        case roadClosure = "road_closure"
        /// Road hazard
        case roadHazard = "road_hazard"
        /// Weather
        case weather

        /// Undefined
        case undefined
    }

    /// Represents the impact of the incident on local traffic.
    public enum Impact: String, Codable, Sendable {
        /// Unknown impact
        case unknown
        /// Critical impact
        case critical
        /// Major impact
        case major
        /// Minor impact
        case minor
        /// Low impact
        case low
    }

    private struct CongestionContainer: Codable, ForeignMemberContainer, Sendable {
        var foreignMembers: JSONObject = [:]

        // `Directions` define this as service value to indicate "no congestion calculated"
        // see: https://docs.mapbox.com/api/navigation/directions/#incident-object
        private static let CongestionUnavailableKey = 101

        enum CodingKeys: String, CodingKey {
            case value
        }

        let value: Int
        var clampedValue: Int? {
            value == Self.CongestionUnavailableKey ? nil : value
        }

        init(value: Int) {
            self.value = value
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.value = try container.decode(Int.self, forKey: .value)

            try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(value, forKey: .value)

            try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
        }
    }

    /// Incident identifier
    public var identifier: String
    /// The kind of an incident
    ///
    /// This value is set to `nil` if ``kind`` value is not supported.
    public var kind: Kind? {
        return Kind(rawValue: rawKind)
    }

    var rawKind: String
    /// Short description of an incident. May be used as an additional info.
    public var description: String
    /// Date when incident item was created.
    public var creationDate: Date
    /// Date when incident happened.
    public var startDate: Date
    /// Date when incident shall end.
    public var endDate: Date
    /// Shows severity of an incident. May be not available for all incident types.
    public var impact: Impact?
    /// Provides additional classification of an incident. May be not available for all incident types.
    public var subtype: String?
    /// Breif description of the subtype. May be not available for all incident types and is not available if
    /// ``subtype`` is `nil`.
    public var subtypeDescription: String?
    /// The three-letter ISO 3166-1 alpha-3 code for the country the incident is located in. Example: "USA".
    public var countryCodeAlpha3: String?
    /// The two-letter ISO 3166-1 alpha-2 code for the country the incident is located in. Example: "US".
    public var countryCode: String?
    /// If this is true then the road has been completely closed.
    public var roadIsClosed: Bool?
    /// A long description of the incident in a human-readable format.
    public var longDescription: String?
    /// The number of items in the ``lanesBlocked``.
    public var numberOfBlockedLanes: Int?
    /// Information about the amount of congestion on the road around the incident.
    ///
    /// A number between 0 and 100 representing the level of congestion caused by the incident. The higher the number,
    /// the more congestion there is. A value of 0 means there is no congestion on the road. A value of 100 means that
    /// the road is closed.
    public var congestionLevel: NumericCongestionLevel?
    /// List of roads names affected by the incident.
    ///
    /// Alternate road names are separated by a /. The list is ordered from the first affected road to the last one that
    /// the incident lies on.
    public var affectedRoadNames: [String]?
    /// Contains list of ISO 14819-2:2013 codes
    ///
    /// See https://www.iso.org/standard/59231.html for details
    public var alertCodes: Set<Int>
    /// A list of lanes, affected by the incident
    ///
    /// `nil` value indicates that lanes data is not available
    public var lanesBlocked: BlockedLanes?
    /// The range of segments within the overall leg, where the incident spans.
    public var shapeIndexRange: Range<Int>

    public init(
        identifier: String,
        type: Kind,
        description: String,
        creationDate: Date,
        startDate: Date,
        endDate: Date,
        impact: Impact?,
        subtype: String?,
        subtypeDescription: String?,
        alertCodes: Set<Int>,
        lanesBlocked: BlockedLanes?,
        shapeIndexRange: Range<Int>,
        countryCodeAlpha3: String? = nil,
        countryCode: String? = nil,
        roadIsClosed: Bool? = nil,
        longDescription: String? = nil,
        numberOfBlockedLanes: Int? = nil,
        congestionLevel: NumericCongestionLevel? = nil,
        affectedRoadNames: [String]? = nil
    ) {
        self.identifier = identifier
        self.rawKind = type.rawValue
        self.description = description
        self.creationDate = creationDate
        self.startDate = startDate
        self.endDate = endDate
        self.impact = impact
        self.subtype = subtype
        self.subtypeDescription = subtypeDescription
        self.alertCodes = alertCodes
        self.lanesBlocked = lanesBlocked
        self.shapeIndexRange = shapeIndexRange
        self.countryCodeAlpha3 = countryCodeAlpha3
        self.countryCode = countryCode
        self.roadIsClosed = roadIsClosed
        self.longDescription = longDescription
        self.numberOfBlockedLanes = numberOfBlockedLanes
        self.congestionLevel = congestionLevel
        self.affectedRoadNames = affectedRoadNames
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let formatter = ISO8601DateFormatter()

        self.identifier = try container.decode(String.self, forKey: .identifier)
        self.rawKind = try container.decode(String.self, forKey: .type)

        self.description = try container.decode(String.self, forKey: .description)

        if let date = try formatter.date(from: container.decode(String.self, forKey: .creationDate)) {
            self.creationDate = date
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .creationDate,
                in: container,
                debugDescription: "`Intersection.creationTime` is encoded with invalid format."
            )
        }
        if let date = try formatter.date(from: container.decode(String.self, forKey: .startDate)) {
            self.startDate = date
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .startDate,
                in: container,
                debugDescription: "`Intersection.startTime` is encoded with invalid format."
            )
        }
        if let date = try formatter.date(from: container.decode(String.self, forKey: .endDate)) {
            self.endDate = date
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .endDate,
                in: container,
                debugDescription: "`Intersection.endTime` is encoded with invalid format."
            )
        }

        self.impact = try container.decodeIfPresent(Impact.self, forKey: .impact)
        self.subtype = try container.decodeIfPresent(String.self, forKey: .subtype)
        self.subtypeDescription = try container.decodeIfPresent(String.self, forKey: .subtypeDescription)
        self.alertCodes = try container.decode(Set<Int>.self, forKey: .alertCodes)

        self.lanesBlocked = try container.decodeIfPresent(BlockedLanes.self, forKey: .lanesBlocked)

        let geometryIndexStart = try container.decode(Int.self, forKey: .geometryIndexStart)
        let geometryIndexEnd = try container.decode(Int.self, forKey: .geometryIndexEnd)
        self.shapeIndexRange = geometryIndexStart..<geometryIndexEnd

        self.countryCodeAlpha3 = try container.decodeIfPresent(String.self, forKey: .countryCodeAlpha3)
        self.countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode)
        self.roadIsClosed = try container.decodeIfPresent(Bool.self, forKey: .roadIsClosed)
        self.longDescription = try container.decodeIfPresent(String.self, forKey: .longDescription)
        self.numberOfBlockedLanes = try container.decodeIfPresent(Int.self, forKey: .numberOfBlockedLanes)
        let congestionContainer = try container.decodeIfPresent(CongestionContainer.self, forKey: .congestionLevel)
        self.congestionLevel = congestionContainer?.clampedValue
        self.congestionForeignMembers = congestionContainer?.foreignMembers ?? [:]
        self.affectedRoadNames = try container.decodeIfPresent([String].self, forKey: .affectedRoadNames)
        try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let formatter = ISO8601DateFormatter()

        try container.encode(identifier, forKey: .identifier)
        try container.encode(rawKind, forKey: .type)
        try container.encode(description, forKey: .description)
        try container.encode(formatter.string(from: creationDate), forKey: .creationDate)
        try container.encode(formatter.string(from: startDate), forKey: .startDate)
        try container.encode(formatter.string(from: endDate), forKey: .endDate)
        try container.encodeIfPresent(impact, forKey: .impact)
        try container.encodeIfPresent(subtype, forKey: .subtype)
        try container.encodeIfPresent(subtypeDescription, forKey: .subtypeDescription)
        try container.encode(alertCodes, forKey: .alertCodes)
        try container.encodeIfPresent(lanesBlocked, forKey: .lanesBlocked)
        try container.encode(shapeIndexRange.lowerBound, forKey: .geometryIndexStart)
        try container.encode(shapeIndexRange.upperBound, forKey: .geometryIndexEnd)
        try container.encodeIfPresent(countryCodeAlpha3, forKey: .countryCodeAlpha3)
        try container.encodeIfPresent(countryCode, forKey: .countryCode)
        try container.encodeIfPresent(roadIsClosed, forKey: .roadIsClosed)
        try container.encodeIfPresent(longDescription, forKey: .longDescription)
        try container.encodeIfPresent(numberOfBlockedLanes, forKey: .numberOfBlockedLanes)
        if let congestionLevel {
            var congestionContainer = CongestionContainer(value: congestionLevel)
            congestionContainer.foreignMembers = congestionForeignMembers
            try container.encode(congestionContainer, forKey: .congestionLevel)
        }
        try container.encodeIfPresent(affectedRoadNames, forKey: .affectedRoadNames)

        try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
    }
}
