import Foundation
import Turf

/// A ``RouteNotification`` object describes a notification about a route leg, such as a safety warning
/// or a violation of user-specified routing constraints.
///
/// Notifications are returned in the ``RouteLeg/notifications`` property when you request directions with
/// the `notifications` parameter. Available on `driving` and `driving-traffic` profiles.
public struct RouteNotification: Codable, Equatable, ForeignMemberContainer, Sendable {
    public var foreignMembers: JSONObject = [:]

    private enum CodingKeys: String, CodingKey {
        case type
        case subtype
        case refreshType = "refresh_type"
        case geometryIndex = "geometry_index"
        case geometryIndexStart = "geometry_index_start"
        case geometryIndexEnd = "geometry_index_end"
        case stationId = "station_id"
        case reason
        case details
    }

    // MARK: Notification Kind

    /// Defines the type of a route notification.
    ///
    /// Each notification belongs to one of two types: a ``Kind/violation`` when a user-set routing
    /// constraint could not be satisfied, or a ``Kind/alert`` when an implicit routing preference
    /// could not be satisfied.
    public struct Kind: Codable, Hashable, RawRepresentable, Sendable {
        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public var rawValue: String

        /// A violation: a user-specified routing constraint could not be satisfied.
        ///
        /// Examples: the route contains an unpaved segment while `exclude=unpaved` was requested,
        /// or the vehicle height exceeds the limit of a road on the route.
        public static let violation: Kind = .init(rawValue: "violation")
        /// An alert: an implicit routing preference could not be satisfied.
        ///
        /// Examples: the route crosses a country border, or an EV charging station is unavailable.
        public static let alert: Kind = .init(rawValue: "alert")
    }

    /// Defines whether the notification is based on static map data or dynamic (live) data.
    public struct RefreshType: Codable, Hashable, RawRepresentable, Sendable {
        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public var rawValue: String

        /// The notification is based on static map data and will not change during route refresh.
        public static let `static`: RefreshType = .init(rawValue: "static")
        /// The notification is based on dynamic (live traffic) data and may change during route refresh.
        public static let dynamic: RefreshType = .init(rawValue: "dynamic")
    }

    /// Defines known notification subtypes.
    public struct Subtype: Codable, Hashable, RawRepresentable, Sendable {
        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public var rawValue: String

        // MARK: Violation subtypes

        /// The vehicle height exceeds the maximum allowed height on the road.
        ///
        /// Provided when `max_height` is specified in the request.
        public static let maxHeight: Subtype = .init(rawValue: "maxHeight")
        /// The vehicle width exceeds the maximum allowed width on the road.
        ///
        /// Provided when `max_width` is specified in the request.
        public static let maxWidth: Subtype = .init(rawValue: "maxWidth")
        /// The vehicle weight exceeds the maximum allowed weight on the road.
        ///
        /// Provided when `max_weight` is specified in the request.
        public static let maxWeight: Subtype = .init(rawValue: "maxWeight")
        /// The route contains an unpaved road segment while `exclude=unpaved` was requested.
        public static let unpaved: Subtype = .init(rawValue: "unpaved")
        /// The route passes through a tunnel while `exclude=tunnel` was requested.
        public static let tunnel: Subtype = .init(rawValue: "tunnel")
        /// The route passes through a road excluded by a coordinate point while `exclude=point(...)` was requested.
        public static let pointExclusion: Subtype = .init(rawValue: "pointExclusion")
        /// The route crosses a country border.
        ///
        /// Returned as a ``Kind/violation`` when `exclude=country_border` was requested,
        /// or as a ``Kind/alert`` otherwise.
        public static let countryBorderCrossing: Subtype = .init(rawValue: "countryBorderCrossing")
        /// The route crosses a state border.
        ///
        /// Returned as a ``Kind/violation`` when `exclude=state_border` was requested,
        /// or as a ``Kind/alert`` otherwise.
        public static let stateBorderCrossing: Subtype = .init(rawValue: "stateBorderCrossing")
        /// The EV battery charge level at a charging station is below the requested minimum.
        ///
        /// Only applicable when `engine=electric`. See the `ev_min_charge_at_charging_station` parameter.
        public static let evMinChargeAtChargingStation: Subtype = .init(rawValue: "evMinChargeAtChargingStation")
        /// The EV battery charge level at the destination is below the requested minimum.
        ///
        /// Only applicable when `engine=electric`. See the `ev_min_charge_at_destination` parameter.
        public static let evMinChargeAtDestination: Subtype = .init(rawValue: "evMinChargeAtDestination")

        // MARK: Alert subtypes

        /// The EV battery charge transitioned to zero or below for the first time on a leg.
        ///
        /// Only applicable when `engine=electric`. Not emitted if the leg starts with zero charge.
        public static let evInsufficientCharge: Subtype = .init(rawValue: "evInsufficientCharge")
        /// An EV charging station planned for the route became unavailable.
        ///
        /// The ``RouteNotification/reason`` property contains the cause: `"outOfOrder"` or `"occupied"`.
        /// Only applicable when `engine=electric`.
        public static let stationUnavailable: Subtype = .init(rawValue: "stationUnavailable")
    }

    // MARK: Notification Details

    /// Additional details specific to the notification type and subtype.
    public struct Details: Codable, Equatable, ForeignMemberContainer, Sendable {
        public var foreignMembers: JSONObject = [:]

        private enum CodingKeys: String, CodingKey {
            case requestedValue = "requested_value"
            case actualValue = "actual_value"
            case unit
            case message
        }

        /// The value specified in the routing request (for example, the requested max vehicle height in meters).
        public var requestedValue: String?
        /// The actual value found on the road (for example, the road's height limit in meters).
        public var actualValue: String?
        /// The unit of measurement associated with ``actualValue`` and ``requestedValue``.
        public var unit: String?
        /// A human-readable description of the notification.
        public var message: String?

        public init(
            requestedValue: String? = nil,
            actualValue: String? = nil,
            unit: String? = nil,
            message: String? = nil
        ) {
            self.requestedValue = requestedValue
            self.actualValue = actualValue
            self.unit = unit
            self.message = message
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.requestedValue = try container.decodeIfPresent(String.self, forKey: .requestedValue)
            self.actualValue = try container.decodeIfPresent(String.self, forKey: .actualValue)
            self.unit = try container.decodeIfPresent(String.self, forKey: .unit)
            self.message = try container.decodeIfPresent(String.self, forKey: .message)

            try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(requestedValue, forKey: .requestedValue)
            try container.encodeIfPresent(actualValue, forKey: .actualValue)
            try container.encodeIfPresent(unit, forKey: .unit)
            try container.encodeIfPresent(message, forKey: .message)

            try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
        }
    }

    // MARK: Properties

    /// The notification type.
    ///
    /// Compare against the static constants on ``Kind`` (e.g. ``Kind/violation``, ``Kind/alert``).
    /// Unknown values from the API are preserved in ``Kind/rawValue``.
    public var kind: Kind

    /// The notification subtype, if present.
    ///
    /// Compare against the static constants on ``Subtype`` (e.g. ``Subtype/maxHeight``,
    /// ``Subtype/countryBorderCrossing``). Unknown values from the API are preserved in ``Subtype/rawValue``.
    public var subtype: Subtype?

    /// Whether the notification is based on static map data or dynamic (live traffic) data.
    public var refreshType: RefreshType?

    /// The position in the leg geometry coordinate list where a point notification occurs.
    ///
    /// This is mutually exclusive with ``geometryIndexStart`` and ``geometryIndexEnd``. Only one of the pair
    /// or the point index will be present on any given notification.
    public var geometryIndex: Int?

    /// The start position in the leg geometry coordinate list where a range notification begins.
    ///
    /// This is mutually exclusive with ``geometryIndex``.
    public var geometryIndexStart: Int?

    /// The end position in the leg geometry coordinate list where a range notification ends.
    ///
    /// This is mutually exclusive with ``geometryIndex``.
    public var geometryIndexEnd: Int?

    /// The unique identifier of the EV charging station associated with this notification.
    ///
    /// Only set when the notification concerns an EV charging station (for example, ``Subtype/stationUnavailable``).
    public var stationId: String?

    /// The reason the notification was issued.
    ///
    /// For ``Subtype/stationUnavailable`` notifications, possible values are `"outOfOrder"` and `"occupied"`.
    public var reason: String?

    /// Additional details about the notification, specific to the type and subtype.
    public var details: Details?

    // MARK: Initializers

    public init(
        kind: Kind,
        subtype: Subtype? = nil,
        refreshType: RefreshType,
        geometryIndex: Int? = nil,
        geometryIndexStart: Int? = nil,
        geometryIndexEnd: Int? = nil,
        stationId: String? = nil,
        reason: String? = nil,
        details: Details? = nil
    ) {
        self.kind = kind
        self.subtype = subtype
        self.refreshType = refreshType
        self.geometryIndex = geometryIndex
        self.geometryIndexStart = geometryIndexStart
        self.geometryIndexEnd = geometryIndexEnd
        self.stationId = stationId
        self.reason = reason
        self.details = details
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.kind = try container.decode(Kind.self, forKey: .type)
        self.subtype = try container.decodeIfPresent(Subtype.self, forKey: .subtype)
        self.refreshType = try container.decodeIfPresent(RefreshType.self, forKey: .refreshType)
        self.geometryIndex = try container.decodeIfPresent(Int.self, forKey: .geometryIndex)
        self.geometryIndexStart = try container.decodeIfPresent(Int.self, forKey: .geometryIndexStart)
        self.geometryIndexEnd = try container.decodeIfPresent(Int.self, forKey: .geometryIndexEnd)
        self.stationId = try container.decodeIfPresent(String.self, forKey: .stationId)
        self.reason = try container.decodeIfPresent(String.self, forKey: .reason)
        self.details = try container.decodeIfPresent(Details.self, forKey: .details)

        try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .type)
        try container.encodeIfPresent(subtype, forKey: .subtype)
        try container.encodeIfPresent(refreshType, forKey: .refreshType)
        try container.encodeIfPresent(geometryIndex, forKey: .geometryIndex)
        try container.encodeIfPresent(geometryIndexStart, forKey: .geometryIndexStart)
        try container.encodeIfPresent(geometryIndexEnd, forKey: .geometryIndexEnd)
        try container.encodeIfPresent(stationId, forKey: .stationId)
        try container.encodeIfPresent(reason, forKey: .reason)
        try container.encodeIfPresent(details, forKey: .details)

        try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
    }
}
