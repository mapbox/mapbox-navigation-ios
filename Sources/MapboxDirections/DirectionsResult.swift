import Foundation
import Turf

public enum DirectionsResultCodingKeys: String, CodingKey, CaseIterable {
    case shape = "geometry"
    case legs
    case distance
    case expectedTravelTime = "duration"
    case typicalTravelTime = "duration_typical"
    case directionsOptions
    case speechLocale = "voiceLocale"
}

public struct DirectionsCodingKey: CodingKey {
    public var intValue: Int? { nil }
    public init?(intValue: Int) {
        nil
    }

    public let stringValue: String
    public init(stringValue: String) {
        self.stringValue = stringValue
    }

    public static func directionsResult(_ key: DirectionsResultCodingKeys) -> Self {
        .init(stringValue: key.rawValue)
    }
}

/// A `DirectionsResult` represents a result returned from either the Mapbox Directions service.
///
/// You do not create instances of this class directly. Instead, you receive ``Route`` or ``Match`` objects when you
/// request directions using the `Directions.calculate(_:completionHandler:)` or
/// `Directions.calculateRoutes(matching:completionHandler:)` method.
public protocol DirectionsResult: Codable, ForeignMemberContainer, Equatable, Sendable {
    // MARK: Getting the Shape of the Route

    /// The roads or paths taken as a contiguous polyline.
    ///
    /// The shape may be `nil` or simplified depending on the ``DirectionsOptions/routeShapeResolution`` property of the
    /// original ``RouteOptions`` or ``MatchOptions`` object.
    ///
    /// Using the [Mapbox Maps SDK for iOS](https://docs.mapbox.com/ios/maps/) or [Mapbox Maps SDK for
    /// macOS](https://mapbox.github.io/mapbox-gl-native/macos/), you can create an `MGLPolyline` object using these
    /// coordinates to display an overview of the route on an `MGLMapView`.
    var shape: LineString? { get }

    // MARK: Getting the Legs Along the Route

    /// The legs that are traversed in order.
    ///
    /// The number of legs in this array depends on the number of waypoints. A route with two waypoints (the source and
    /// destination) has one leg, a route with three waypoints (the source, an intermediate waypoint, and the
    /// destination) has two legs, and so on.
    ///
    /// To determine the name of the route, concatenate the names of the route’s legs.
    var legs: [RouteLeg] { get set }

    // MARK: Getting Statistics About the Route

    /// The route’s distance, measured in meters.
    ///
    /// The value of this property accounts for the distance that the user must travel to traverse the path of the
    /// route. It is the sum of the ``RouteLeg/distance`` properties of the route’s legs, not the sum of the direct
    /// distances between the route’s waypoints. You should not assume that the user would travel along this distance at
    /// a fixed speed.
    var distance: Turf.LocationDistance { get }

    /// The route’s expected travel time, measured in seconds.
    ///
    /// The value of this property reflects the time it takes to traverse the entire route. It is the sum of the
    /// ``expectedTravelTime`` properties of the route’s legs. If the route was calculated using the
    /// ``ProfileIdentifier/automobileAvoidingTraffic`` profile, this property reflects current traffic conditions at
    /// the time of the request, not necessarily the traffic conditions at the time the user would begin the route. For
    /// other profiles, this property reflects travel time under ideal conditions and does not account for traffic
    /// congestion. If the route makes use of a ferry or train, the actual travel time may additionally be subject to
    /// the schedules of those services.
    ///
    /// Do not assume that the user would travel along the route at a fixed speed. For more granular travel times, use
    /// the ``RouteLeg/expectedTravelTime`` or ``RouteStep/expectedTravelTime``. For even more granularity, specify the
    /// ``AttributeOptions/expectedTravelTime`` option and use the ``RouteLeg/expectedSegmentTravelTimes`` property.
    var expectedTravelTime: TimeInterval { get set }

    /// The route’s typical travel time, measured in seconds.
    ///
    /// The value of this property reflects the typical time it takes to traverse the entire route. It is the sum of the
    /// ``typicalTravelTime`` properties of the route’s legs. This property is available when using the
    /// ``ProfileIdentifier/automobileAvoidingTraffic`` profile. This property reflects typical traffic conditions at
    /// the time of the request, not necessarily the typical traffic conditions at the time the user would begin the
    /// route. If the route makes use of a ferry, the typical travel time may additionally be subject to the schedule of
    /// this service.
    ///
    /// Do not assume that the user would travel along the route at a fixed speed. For more granular typical travel
    /// times, use the ``RouteLeg/typicalTravelTime`` or ``RouteStep/typicalTravelTime``.
    var typicalTravelTime: TimeInterval? { get set }

    // MARK: Configuring Speech Synthesis

    /// The locale to use for spoken instructions.
    ///
    /// This locale is specific to Mapbox Voice API. If `nil` is returned, the instruction should be spoken with an
    /// alternative speech synthesizer.
    var speechLocale: Locale? { get set }

    // MARK: Auditing the Server Response

    /// The time immediately before a `Directions` object fetched this result.
    ///
    /// If you manually start fetching a task returned by `Directions.url(forCalculating:)`, this property is set to
    /// `nil`; use the `URLSessionTaskTransactionMetrics.fetchStartDate` property instead. This property may also be set
    /// to `nil` if you create this result from a JSON object or encoded object.
    ///
    /// This property does not persist after encoding and decoding.
    var fetchStartDate: Date? { get set }

    /// The time immediately before a `Directions` object received the last byte of this result.
    ///
    /// If you manually start fetching a task returned by `Directions.url(forCalculating:)`, this property is set to
    /// `nil`; use the `URLSessionTaskTransactionMetrics.responseEndDate` property instead. This property may also be
    /// set to `nil` if you create this result from a JSON object or encoded object.
    ///
    /// This property does not persist after encoding and decoding.
    var responseEndDate: Date? { get set }

    /// Internal indicator of whether response contained the ``speechLocale`` entry.
    ///
    /// Directions API includes ``speechLocale`` if ``DirectionsOptions/includesSpokenInstructions`` option was enabled
    /// in the request.
    ///
    /// This property persists after encoding and decoding.
    var responseContainsSpeechLocale: Bool { get }

    var legSeparators: [Waypoint?] { get set }
}

extension DirectionsResult {
    public var legSeparators: [Waypoint?] {
        get {
            return legs.isEmpty ? [] : ([legs[0].source] + legs.map(\.destination))
        }
        set {
            let endpointsByLeg = zip(newValue, newValue.suffix(from: 1))
            var legIdx = legs.startIndex
            for endpoint in endpointsByLeg where legIdx != legs.endIndex {
                legs[legIdx].source = endpoint.0
                legs[legIdx].destination = endpoint.1
                legIdx = legs.index(after: legIdx)
            }
        }
    }

    // MARK: - Decode

    static func decodeLegs(
        using container: KeyedDecodingContainer<DirectionsCodingKey>,
        options: DirectionsOptions
    ) throws -> [RouteLeg] {
        var legs = try container.decode([RouteLeg].self, forKey: .directionsResult(.legs))
        legs.populate(waypoints: options.legSeparators)
        return legs
    }

    static func decodeDistance(
        using container: KeyedDecodingContainer<DirectionsCodingKey>
    ) throws -> Turf.LocationDistance {
        try container.decode(Turf.LocationDistance.self, forKey: .directionsResult(.distance))
    }

    static func decodeExpectedTravelTime(
        using container: KeyedDecodingContainer<DirectionsCodingKey>
    ) throws -> TimeInterval {
        try container.decode(TimeInterval.self, forKey: .directionsResult(.expectedTravelTime))
    }

    static func decodeTypicalTravelTime(
        using container: KeyedDecodingContainer<DirectionsCodingKey>
    ) throws -> TimeInterval? {
        try container.decodeIfPresent(TimeInterval.self, forKey: .directionsResult(.typicalTravelTime))
    }

    static func decodeShape(
        using container: KeyedDecodingContainer<DirectionsCodingKey>
    ) throws -> LineString? {
        try container.decodeIfPresent(PolyLineString.self, forKey: .directionsResult(.shape))
            .map(LineString.init(polyLineString:))
    }

    static func decodeSpeechLocale(
        using container: KeyedDecodingContainer<DirectionsCodingKey>
    ) throws -> Locale? {
        try container.decodeIfPresent(String.self, forKey: .directionsResult(.speechLocale))
            .map(Locale.init(identifier:))
    }

    static func decodeResponseContainsSpeechLocale(
        using container: KeyedDecodingContainer<DirectionsCodingKey>
    ) throws -> Bool {
        container.contains(.directionsResult(.speechLocale))
    }

    // MARK: - Encode

    func encodeLegs(
        into container: inout KeyedEncodingContainer<DirectionsCodingKey>
    ) throws {
        try container.encode(legs, forKey: .directionsResult(.legs))
    }

    func encodeShape(
        into container: inout KeyedEncodingContainer<DirectionsCodingKey>,
        options: DirectionsOptions?
    ) throws {
        guard let shape else { return }

        let shapeFormat = options?.shapeFormat ?? .default
        let polyLineString = PolyLineString(lineString: shape, shapeFormat: shapeFormat)
        try container.encode(polyLineString, forKey: .directionsResult(.shape))
    }

    func encodeDistance(
        into container: inout KeyedEncodingContainer<DirectionsCodingKey>
    ) throws {
        try container.encode(distance, forKey: .directionsResult(.distance))
    }

    func encodeExpectedTravelTime(
        into container: inout KeyedEncodingContainer<DirectionsCodingKey>
    ) throws {
        try container.encode(expectedTravelTime, forKey: .directionsResult(.expectedTravelTime))
    }

    func encodeTypicalTravelTime(
        into container: inout KeyedEncodingContainer<DirectionsCodingKey>
    ) throws {
        try container.encodeIfPresent(typicalTravelTime, forKey: .directionsResult(.typicalTravelTime))
    }

    func encodeSpeechLocale(
        into container: inout KeyedEncodingContainer<DirectionsCodingKey>
    ) throws {
        if responseContainsSpeechLocale {
            try container.encode(speechLocale?.identifier, forKey: .directionsResult(.speechLocale))
        }
    }
}
