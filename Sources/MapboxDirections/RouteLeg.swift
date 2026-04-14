import Foundation
import Turf

/// A ``RouteLeg`` object defines a single leg of a route between two waypoints. If the overall route has only two
/// waypoints, it has a single ``RouteLeg`` object that covers the entire route. The route leg object includes
/// information about the leg, such as its name, distance, and expected travel time. Depending on the criteria used to
/// calculate the route, the route leg object may also include detailed turn-by-turn instructions.
///
/// You do not create instances of this class directly. Instead, you receive route leg objects as part of route objects
/// when you request directions using the `Directions.calculate(_:completionHandler:)` method.
public struct RouteLeg: Codable, ForeignMemberContainer, Equatable, Sendable {
    public var foreignMembers: JSONObject = [:]

    /// Foreign attribute arrays associated with this leg.
    ///
    /// This library does not officially support any attribute that is documented as a “beta” annotation type in the
    /// Mapbox Directions API response format, but you can get and set it as an element of this `JSONObject`. It is
    /// round-tripped to the `annotation` property in JSON.
    ///
    /// For non-attribute-related foreign members, use the ``foreignMembers`` property.
    public var attributesForeignMembers: JSONObject = [:]

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case source
        case destination
        case steps
        case name = "summary"
        case distance
        case expectedTravelTime = "duration"
        case typicalTravelTime = "duration_typical"
        case profileIdentifier
        case annotation
        case administrativeRegions = "admins"
        case incidents
        case viaWaypoints = "via_waypoints"
        case closures
    }

    // MARK: Creating a Leg

    /// Initializes a route leg.
    /// - Parameters:
    ///   - steps: The steps that are traversed in order.
    ///   - name: A name that describes the route leg.
    ///   - distance: The route leg’s expected travel time, measured in seconds.
    ///   - expectedTravelTime: The route leg’s expected travel time, measured in seconds.
    ///   - typicalTravelTime: The route leg’s typical travel time, measured in seconds.
    ///   - profileIdentifier: The primary mode of transportation for the route leg.
    public init(
        steps: [RouteStep],
        name: String,
        distance: Turf.LocationDistance,
        expectedTravelTime: TimeInterval,
        typicalTravelTime: TimeInterval? = nil,
        profileIdentifier: ProfileIdentifier
    ) {
        self.steps = steps
        self.name = name
        self.distance = distance
        self.expectedTravelTime = expectedTravelTime
        self.typicalTravelTime = typicalTravelTime
        self.profileIdentifier = profileIdentifier

        self.segmentDistances = nil
        self.expectedSegmentTravelTimes = nil
        self.segmentSpeeds = nil
        self.segmentCongestionLevels = nil
        self.segmentNumericCongestionLevels = nil
    }

    /// Creates a route leg from a decoder.
    /// - Precondition: If the decoder is decoding JSON data from an API response, the `Decoder.userInfo` dictionary
    /// must contain a ``RouteOptions`` or ``MatchOptions`` object in the ``Swift/CodingUserInfoKey/options`` key. If it
    /// does not, a ``DirectionsCodingError/missingOptions`` error is thrown.
    /// - parameter decoder: The decoder of JSON-formatted API response data or a previously encoded ``RouteLeg``
    /// object.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.source = try container.decodeIfPresent(Waypoint.self, forKey: .source)
        self.destination = try container.decodeIfPresent(Waypoint.self, forKey: .destination)
        self.name = try container.decode(String.self, forKey: .name)
        self.distance = try container.decode(Turf.LocationDistance.self, forKey: .distance)
        self.expectedTravelTime = try container.decode(TimeInterval.self, forKey: .expectedTravelTime)
        self.typicalTravelTime = try container.decodeIfPresent(TimeInterval.self, forKey: .typicalTravelTime)

        if let profileIdentifier = try container.decodeIfPresent(ProfileIdentifier.self, forKey: .profileIdentifier) {
            self.profileIdentifier = profileIdentifier
        } else if let options = decoder.userInfo[.options] as? DirectionsOptions {
            self.profileIdentifier = options.profileIdentifier
        } else {
            throw DirectionsCodingError.missingOptions
        }

        if let admins = try container.decodeIfPresent([AdministrativeRegion].self, forKey: .administrativeRegions) {
            self.administrativeRegions = admins
            self.steps = try RouteStep.decode(
                from: container.superDecoder(forKey: .steps),
                administrativeRegions: administrativeRegions!
            )
        } else {
            self.steps = try container.decode([RouteStep].self, forKey: .steps)
        }

        if let attributes = try container.decodeIfPresent(Attributes.self, forKey: .annotation) {
            self.attributes = attributes
            self.attributesForeignMembers = attributes.foreignMembers
        }

        if let incidents = try container.decodeIfPresent([Incident].self, forKey: .incidents) {
            self.incidents = incidents
        }

        if let closures = try container.decodeIfPresent([Closure].self, forKey: .closures) {
            self.closures = closures
        }

        if let viaWaypoints = try container.decodeIfPresent([SilentWaypoint].self, forKey: .viaWaypoints) {
            self.viaWaypoints = viaWaypoints
        }

        try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(source, forKey: .source)
        try container.encode(destination, forKey: .destination)
        try container.encode(steps, forKey: .steps)
        try container.encode(name, forKey: .name)
        try container.encode(distance, forKey: .distance)
        try container.encode(expectedTravelTime, forKey: .expectedTravelTime)
        try container.encodeIfPresent(typicalTravelTime, forKey: .typicalTravelTime)
        try container.encode(profileIdentifier, forKey: .profileIdentifier)

        var attributes = attributes
        if !attributes.isEmpty {
            attributes.foreignMembers = attributesForeignMembers
            try container.encode(attributes, forKey: .annotation)
        }

        if let admins = administrativeRegions {
            try container.encode(admins, forKey: .administrativeRegions)
        }

        if let incidents {
            try container.encode(incidents, forKey: .incidents)
        }
        if let closures {
            try container.encode(closures, forKey: .closures)
        }

        if let viaWaypoints {
            try container.encode(viaWaypoints, forKey: .viaWaypoints)
        }

        try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
    }

    // MARK: Getting the Endpoints of the Leg

    /// The starting point of the route leg.
    ///
    /// Unless this is the first leg of the route, the source of this leg is the same as the destination of the previous
    /// leg.
    ///
    /// This property is set to `nil` if the leg was decoded from a JSON RouteLeg object.
    public var source: Waypoint?

    /// The endpoint of the route leg.
    ///
    /// Unless this is the last leg of the route, the destination of this leg is the same as the source of the next leg.
    ///
    /// This property is set to `nil` if the leg was decoded from a JSON RouteLeg object.
    public var destination: Waypoint?

    // MARK: Getting the Steps Along the Leg

    /// An array of one or more ``RouteStep`` objects representing the steps for traversing this leg of the route.
    ///
    /// Each route step object corresponds to a distinct maneuver and the approach to the next maneuver.
    ///
    /// This array is empty if the original ``RouteOptions`` object’s ``DirectionsOptions/includesSteps`` property is
    /// set to
    /// `false`.
    public let steps: [RouteStep]

    /// The ranges of each step’s segments within the overall leg.
    ///
    /// Each range corresponds to an element of the ``steps`` property. Use this property to safely subscript
    /// segment-based properties such as ``segmentCongestionLevels`` and ``segmentMaximumSpeedLimits``.
    ///
    /// This array is empty if the original ``RouteOptions`` object’s ``DirectionsOptions/includesSteps`` property is
    /// set to
    /// `false`.
    public private(set) lazy var segmentRangesByStep: [Range<Int>] = {
        var segmentRangesByStep: [Range<Int>] = []
        var currentStepStartIndex = 0
        for step in steps {
            if let coordinates = step.shape?.coordinates {
                let stepCoordinateCount = step.maneuverType == .arrive ? 0 : coordinates.dropLast().count
                let currentStepEndIndex = currentStepStartIndex.advanced(by: stepCoordinateCount)
                segmentRangesByStep.append(currentStepStartIndex..<currentStepEndIndex)
                currentStepStartIndex = currentStepEndIndex
            } else {
                segmentRangesByStep.append(currentStepStartIndex..<currentStepStartIndex)
            }
        }
        return segmentRangesByStep
    }()

    // MARK: Getting Per-Segment Attributes Along the Leg

    /// An array containing the distance (measured in meters) between each coordinate in the route leg geometry.
    ///
    /// This property is set if the ``DirectionsOptions/attributeOptions`` property contains
    /// ``AttributeOptions/distance``.
    public var segmentDistances: [Turf.LocationDistance]?

    /// An array containing the expected travel time (measured in seconds) between each coordinate in the route leg
    /// geometry.
    ///
    /// These values are dynamic, accounting for any conditions that may change along a segment, such as traffic
    /// congestion if the profile identifier is set to ``ProfileIdentifier/automobileAvoidingTraffic``.
    ///
    /// This property is set if the ``DirectionsOptions/attributeOptions`` property contains
    /// ``AttributeOptions/expectedTravelTime``.
    public var expectedSegmentTravelTimes: [TimeInterval]?

    /// An array containing the expected average speed (measured in meters per second) between each coordinate in the
    /// route leg geometry.
    ///
    /// These values are dynamic; rather than speed limits, they account for the road’s classification and/or any
    /// traffic congestion (if the profile identifier is set to ``ProfileIdentifier/automobileAvoidingTraffic``).
    ///
    /// This property is set if the ``DirectionsOptions/attributeOptions`` property contains ``AttributeOptions/speed``.
    public var segmentSpeeds: [LocationSpeed]?

    /// An array containing the traffic congestion level along each road segment in the route leg geometry.
    ///
    /// Traffic data is available in [a number of countries and territories
    /// worldwide](https://docs.mapbox.com/help/how-mapbox-works/directions/#traffic-data).
    /// You can color-code a route line according to the congestion level along each segment of the route.
    ///
    /// This property is set if the ``DirectionsOptions/attributeOptions`` property contains
    /// ``AttributeOptions/congestionLevel``.
    public var segmentCongestionLevels: [CongestionLevel]?

    /// An array containing the traffic congestion level along each road segment in the route leg geometry in numeric
    /// form.
    ///
    /// Entries may be `nil` if congestion on that segment is not known.
    ///
    ///  Traffic data is available in [a number of countries and territories
    /// worldwide](https://docs.mapbox.com/help/how-mapbox-works/directions/#traffic-data).
    ///
    ///  You can color-code a route line according to the congestion level along each segment of the route.
    ///
    ///  This property is set if the ``DirectionsOptions/attributeOptions`` property contains
    /// ``AttributeOptions/numericCongestionLevel``.
    public var segmentNumericCongestionLevels: [NumericCongestionLevel?]?

    /// An array containing the maximum speed limit along each road segment along the route leg’s shape.
    ///
    /// The maximum speed may be an advisory speed limit for segments where legal limits are not posted, such as highway
    /// entrance and exit ramps. If the speed limit along a particular segment is unknown, it is represented in the
    /// array by a measurement whose value is negative. If the speed is unregulated along the segment, such as on the
    /// German _Autobahn_ system, it is represented by a measurement whose value is `Double.infinity`.
    ///
    /// Speed limit data is available in [a number of countries and territories
    /// worldwide](https://docs.mapbox.com/help/how-mapbox-works/directions/).
    ///
    /// This property is set if the ``DirectionsOptions/attributeOptions`` property contains
    /// ``AttributeOptions/maximumSpeedLimit``.
    public var segmentMaximumSpeedLimits: [Measurement<UnitSpeed>?]?

    /// An array of ``RouteLeg/Closure`` objects describing live-traffic related closures that occur along the route.
    ///
    /// This information is only available for the `mapbox/driving-traffic` profile and when
    /// ``DirectionsOptions/attributeOptions`` property contains ``AttributeOptions/closures``.
    public var closures: [Closure]?

    /// The tendency value conveys the changing state of traffic congestion (increasing, decreasing, constant etc).
    public var trafficTendencies: [TrafficTendency]?

    /// The full collection of attributes along the leg.
    var attributes: Attributes {
        get {
            return Attributes(
                segmentDistances: segmentDistances,
                expectedSegmentTravelTimes: expectedSegmentTravelTimes,
                segmentSpeeds: segmentSpeeds,
                segmentCongestionLevels: segmentCongestionLevels,
                segmentNumericCongestionLevels: segmentNumericCongestionLevels,
                segmentMaximumSpeedLimits: segmentMaximumSpeedLimits,
                trafficTendencies: trafficTendencies
            )
        }
        set {
            segmentDistances = newValue.segmentDistances
            expectedSegmentTravelTimes = newValue.expectedSegmentTravelTimes
            segmentSpeeds = newValue.segmentSpeeds
            segmentCongestionLevels = newValue.segmentCongestionLevels
            segmentNumericCongestionLevels = newValue.segmentNumericCongestionLevels
            segmentMaximumSpeedLimits = newValue.segmentMaximumSpeedLimits
            trafficTendencies = newValue.trafficTendencies
        }
    }

    mutating func refreshAttributes(newAttributes: Attributes, startLegShapeIndex: Int = 0) {
        let refreshRange = PartialRangeFrom(startLegShapeIndex)

        segmentDistances?.replaceIfPossible(subrange: refreshRange, with: newAttributes.segmentDistances)
        expectedSegmentTravelTimes?.replaceIfPossible(
            subrange: refreshRange,
            with: newAttributes.expectedSegmentTravelTimes
        )
        segmentSpeeds?.replaceIfPossible(subrange: refreshRange, with: newAttributes.segmentSpeeds)
        segmentCongestionLevels?.replaceIfPossible(subrange: refreshRange, with: newAttributes.segmentCongestionLevels)
        segmentNumericCongestionLevels?.replaceIfPossible(
            subrange: refreshRange,
            with: newAttributes.segmentNumericCongestionLevels
        )
        segmentMaximumSpeedLimits?.replaceIfPossible(
            subrange: refreshRange,
            with: newAttributes.segmentMaximumSpeedLimits
        )
        trafficTendencies?.replaceIfPossible(subrange: refreshRange, with: newAttributes.trafficTendencies)
    }

    private func adjustShapeIndexRange(_ range: Range<Int>, startLegShapeIndex: Int) -> Range<Int> {
        let startIndex = startLegShapeIndex + range.lowerBound
        let endIndex = startLegShapeIndex + range.upperBound
        return startIndex..<endIndex
    }

    mutating func refreshIncidents(newIncidents: [Incident]?, startLegShapeIndex: Int = 0) {
        incidents = newIncidents?.map { incident in
            var adjustedIncident = incident
            adjustedIncident.shapeIndexRange = adjustShapeIndexRange(
                incident.shapeIndexRange,
                startLegShapeIndex: startLegShapeIndex
            )
            return adjustedIncident
        }
    }

    mutating func refreshClosures(newClosures: [Closure]?, startLegShapeIndex: Int = 0) {
        closures = newClosures?.map { closure in
            var adjustedClosure = closure
            adjustedClosure.shapeIndexRange = adjustShapeIndexRange(
                closure.shapeIndexRange,
                startLegShapeIndex: startLegShapeIndex
            )
            return adjustedClosure
        }
    }

    /// Returns the ISO 3166-1 alpha-2 region code for the administrative region through which the given intersection
    /// passes. The intersection is identified by its step index and intersection index.
    ///
    /// - SeeAlso: ``Intersection/regionCode``
    public func regionCode(atStepIndex stepIndex: Int, intersectionIndex: Int) -> String? {
        // check index ranges
        guard let administrativeRegions,
              stepIndex < steps.count,
              intersectionIndex < steps[stepIndex].administrativeAreaContainerByIntersection?.count ?? -1,
              let adminIndex = steps[stepIndex].administrativeAreaContainerByIntersection?[intersectionIndex]
        else {
            return nil
        }
        return administrativeRegions[adminIndex].countryCode
    }

    // MARK: Getting Statistics About the Leg

    /// A name that describes the route leg.
    ///
    /// The name describes the leg using the most significant roads or trails along the route leg. You can display this
    /// string to the user to help the user can distinguish one route from another based on how the legs of the routes
    /// are named.
    ///
    /// The leg’s name does not identify the start and end points of the leg. To distinguish one leg from another within
    /// the same route, concatenate the ``name`` properties of the ``source`` and ``destination`` waypoints.
    public let name: String

    /// The route leg’s distance, measured in meters.
    ///
    /// The value of this property accounts for the distance that the user must travel to arrive at the destination from
    /// the source. It is not the direct distance between the source and destination, nor should not assume that the
    /// user would travel along this distance at a fixed speed.
    public let distance: Turf.LocationDistance

    /// The route leg’s expected travel time, measured in seconds.
    ///
    /// The value of this property reflects the time it takes to traverse the route leg. If the route was calculated
    /// using the ``ProfileIdentifier/automobileAvoidingTraffic`` profile, this property reflects current traffic
    /// conditions at the time of the request, not necessarily the traffic conditions at the time the user would begin
    /// this leg. For other profiles, this property reflects travel time under ideal conditions and does not account for
    /// traffic congestion. If the leg makes use of a ferry or train, the actual travel time may additionally be subject
    /// to the schedules of those services.
    ///
    /// Do not assume that the user would travel along the leg at a fixed speed. For the expected travel time on each
    /// individual segment along the leg, use the ``RouteStep/expectedTravelTime`` property. For more granularity,
    /// specify the ``AttributeOptions/expectedTravelTime`` option and use the ``expectedSegmentTravelTimes`` property.
    public var expectedTravelTime: TimeInterval

    /// The administrative regions through which the leg passes.
    ///
    /// Items are ordered by appearance, most recent one is at the beginning. This property is set to `nil` if no
    /// administrative region data is available.
    /// You can alse refer to ``Intersection/regionCode`` to get corresponding region string code.
    public var administrativeRegions: [AdministrativeRegion]?

    /// Contains ``Incident``s data which occur during current ``RouteLeg``.
    ///
    /// Items are ordered by appearance, most recent one is at the beginning.
    /// This property is set to `nil` if incidents data is not available.
    public var incidents: [Incident]?

    /// Describes where a particular ``Waypoint`` passed to ``RouteOptions`` matches to the route along a ``RouteLeg``.
    ///
    /// The property is non-nil when for one or several ``Waypoint`` objects passed to ``RouteOptions`` have
    /// ``Waypoint/separatesLegs`` property set to `false`.
    public var viaWaypoints: [SilentWaypoint]?

    /// The route leg’s typical travel time, measured in seconds.
    ///
    /// The value of this property reflects the typical time it takes to traverse the route leg. This property is
    /// available when using the ``ProfileIdentifier/automobileAvoidingTraffic`` profile. This property reflects typical
    /// traffic conditions at the time of the request, not necessarily the typical traffic conditions at the time the
    /// user would begin this leg. If the leg makes use of a ferry, the typical travel time may additionally be subject
    /// to the schedule of this service.
    ///
    /// Do not assume that the user would travel along the route at a fixed speed. For more granular typical travel
    /// times, use the ``RouteStep/typicalTravelTime`` property.
    public var typicalTravelTime: TimeInterval?

    // MARK: Reproducing the Route

    /// The primary mode of transportation for the route leg.
    ///
    /// The value of this property depends on the ``DirectionsOptions/profileIdentifier`` property of the original
    /// ``RouteOptions`` object. This property reflects the primary mode of transportation used for the route leg.
    /// Individual steps along the route leg might use different modes of transportation as necessary.
    public let profileIdentifier: ProfileIdentifier
}

extension RouteLeg: CustomStringConvertible {
    public var description: String {
        return name
    }
}

extension RouteLeg: CustomQuickLookConvertible {
    func debugQuickLookObject() -> Any? {
        let coordinates = steps.reduce([]) { $0 + ($1.shape?.coordinates ?? []) }
        guard !coordinates.isEmpty else {
            return nil
        }
        return debugQuickLookURL(illustrating: LineString(coordinates))
    }
}

extension RouteLeg {
    /// Live-traffic related closure that occured along the route.
    public struct Closure: Codable, Equatable, ForeignMemberContainer, Sendable {
        public var foreignMembers: JSONObject = [:]

        private enum CodingKeys: String, CodingKey {
            case geometryIndexStart = "geometry_index_start"
            case geometryIndexEnd = "geometry_index_end"
        }

        /// The range of segments within the current leg, where the closure spans.
        public var shapeIndexRange: Range<Int>

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let geometryIndexStart = try container.decode(Int.self, forKey: .geometryIndexStart)
            let geometryIndexEnd = try container.decode(Int.self, forKey: .geometryIndexEnd)
            self.shapeIndexRange = geometryIndexStart..<geometryIndexEnd

            try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(shapeIndexRange.lowerBound, forKey: .geometryIndexStart)
            try container.encode(shapeIndexRange.upperBound, forKey: .geometryIndexEnd)

            try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
        }
    }
}

extension [RouteLeg] {
    /// Populates source and destination information for each leg with waypoint information, typically gathered from
    /// ``DirectionsOptions``.
    public mutating func populate(waypoints: [Waypoint]) {
        guard !isEmpty else { return }

        let endpoints = zip(waypoints.prefix(upTo: waypoints.endIndex - 1), waypoints.suffix(from: 1))

        var legIndex: Index = startIndex
        for endpoint in endpoints where legIndex != endIndex {
            self[legIndex].source = endpoint.0
            self[legIndex].destination = endpoint.1

            legIndex = self.index(after: legIndex)
        }
    }
}

extension Array {
    fileprivate mutating func replaceIfPossible(subrange: PartialRangeFrom<Int>, with newElements: Array?) {
        guard let newElements, !newElements.isEmpty else { return }
        let upperBound = subrange.lowerBound + newElements.count

        guard count >= upperBound else { return }

        let adjustedSubrange = subrange.lowerBound..<upperBound
        replaceSubrange(adjustedSubrange, with: newElements)
    }
}

extension RouteLeg {
    public static func == (lhs: RouteLeg, rhs: RouteLeg) -> Bool {
        return lhs.source == rhs.source &&
            lhs.destination == rhs.destination &&
            lhs.steps == rhs.steps &&
            lhs.segmentDistances == rhs.segmentDistances &&
            lhs.expectedSegmentTravelTimes == rhs.expectedSegmentTravelTimes &&
            lhs.segmentSpeeds == rhs.segmentSpeeds &&
            lhs.segmentCongestionLevels == rhs.segmentCongestionLevels &&
            lhs.segmentNumericCongestionLevels == rhs.segmentNumericCongestionLevels &&
            lhs.segmentMaximumSpeedLimits == rhs.segmentMaximumSpeedLimits &&
            lhs.trafficTendencies == rhs.trafficTendencies &&
            lhs.name == rhs.name &&
            lhs.distance == rhs.distance &&
            lhs.expectedTravelTime == rhs.expectedTravelTime &&
            lhs.administrativeRegions == rhs.administrativeRegions &&
            lhs.incidents == rhs.incidents &&
            lhs.viaWaypoints == rhs.viaWaypoints &&
            lhs.typicalTravelTime == rhs.typicalTravelTime &&
            lhs.profileIdentifier == rhs.profileIdentifier
    }
}
