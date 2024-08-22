import Foundation
#if canImport(CoreLocation)
import CoreLocation
#endif
import Turf

/// A ``RouteOptions`` object is a structure that specifies the criteria for results returned by the Mapbox Directions
/// API.
///
/// Pass an instance of this class into the `Directions.calculate(_:completionHandler:)` method.
open class RouteOptions: DirectionsOptions, @unchecked Sendable {
    // MARK: Creating a Route Options Object

    /// Initializes a route options object for routes between the given waypoints and an optional profile identifier.
    /// - Parameters:
    ///   - waypoints: An array of ``Waypoint`` objects representing locations that the route should visit in
    /// chronological order. The array should contain at least two waypoints (the source and destination) and at most 25
    /// waypoints. (Some profiles, such as ``ProfileIdentifier/automobileAvoidingTraffic``, [may have lower
    /// limits](https://www.mapbox.com/api-documentation/#directions).)
    ///   - profileIdentifier: A string specifying the primary mode of transportation for the routes.
    /// ``ProfileIdentifier/automobile`` is used by default.
    ///   - queryItems: URL query items to be parsed and applied as configuration to the resulting options.
    public required init(
        waypoints: [Waypoint],
        profileIdentifier: ProfileIdentifier? = nil,
        queryItems: [URLQueryItem]? = nil
    ) {
        let profilesDisallowingUTurns: [ProfileIdentifier] = [.automobile, .automobileAvoidingTraffic]
        self.allowsUTurnAtWaypoint = !profilesDisallowingUTurns.contains(profileIdentifier ?? .automobile)
        super.init(waypoints: waypoints, profileIdentifier: profileIdentifier, queryItems: queryItems)

        guard let queryItems else {
            return
        }

        let mappedQueryItems = [String: String](
            queryItems.compactMap {
                guard let value = $0.value else { return nil }
                return ($0.name, value)
            },
            uniquingKeysWith: { _, latestValue in
                return latestValue
            }
        )

        if mappedQueryItems[CodingKeys.includesAlternativeRoutes.stringValue] == "true" {
            self.includesAlternativeRoutes = true
        }
        if mappedQueryItems[CodingKeys.includesExitRoundaboutManeuver.stringValue] == "true" {
            self.includesExitRoundaboutManeuver = true
        }
        if let mappedValue = mappedQueryItems[CodingKeys.alleyPriority.stringValue],
           let alleyPriority = Double(mappedValue)
        {
            self.alleyPriority = DirectionsPriority(rawValue: alleyPriority)
        }
        if let mappedValue = mappedQueryItems[CodingKeys.walkwayPriority.stringValue],
           let walkwayPriority = Double(mappedValue)
        {
            self.walkwayPriority = DirectionsPriority(rawValue: walkwayPriority)
        }
        if let mappedValue = mappedQueryItems[CodingKeys.speed.stringValue],
           let speed = LocationSpeed(mappedValue)
        {
            self.speed = speed
        }
        if let mappedValue = mappedQueryItems[CodingKeys.roadClassesToAvoid.stringValue],
           let roadClassesToAvoid = RoadClasses(descriptions: mappedValue.components(separatedBy: ","))
        {
            self.roadClassesToAvoid = roadClassesToAvoid
        }
        if let mappedValue = mappedQueryItems[CodingKeys.roadClassesToAllow.stringValue],
           let roadClassesToAllow = RoadClasses(descriptions: mappedValue.components(separatedBy: ","))
        {
            self.roadClassesToAllow = roadClassesToAllow
        }
        if mappedQueryItems[CodingKeys.refreshingEnabled.stringValue] == "true", profileIdentifier ==
            .automobileAvoidingTraffic
        {
            self.refreshingEnabled = true
        }

        // Making copy of waypoints processed by super class to further update them...
        var waypoints = self.waypoints
        if let mappedValue = mappedQueryItems[CodingKeys.waypointTargets.stringValue] {
            var waypointsIndex = waypoints.startIndex
            let mappedValues = mappedValue.components(separatedBy: ";")
            var mappedValuesIndex = mappedValues.startIndex

            while waypointsIndex < waypoints.endIndex,
                  mappedValuesIndex < mappedValues.endIndex
            {
                guard waypoints[waypointsIndex].separatesLegs else {
                    waypointsIndex = waypoints.index(after: waypointsIndex); continue
                }

                let coordinatesComponents = mappedValues[mappedValuesIndex].components(separatedBy: ",")
                waypoints[waypointsIndex].targetCoordinate = LocationCoordinate2D(
                    latitude: LocationDegrees(coordinatesComponents.last!)!,
                    longitude: LocationDegrees(coordinatesComponents.first!)!
                )
                waypointsIndex = waypoints.index(after: waypointsIndex)
                mappedValuesIndex = mappedValues.index(after: mappedValuesIndex)
            }
        }
        if let mappedValue = mappedQueryItems[CodingKeys.initialManeuverAvoidanceRadius.stringValue],
           let initialManeuverAvoidanceRadius = LocationDistance(mappedValue)
        {
            self.initialManeuverAvoidanceRadius = initialManeuverAvoidanceRadius
        }
        if let mappedValue = mappedQueryItems[CodingKeys.maximumHeight.stringValue],
           let doubleValue = Double(mappedValue)
        {
            self.maximumHeight = Measurement(value: doubleValue, unit: UnitLength.meters)
        }
        if let mappedValue = mappedQueryItems[CodingKeys.maximumWidth.stringValue],
           let doubleValue = Double(mappedValue)
        {
            self.maximumWidth = Measurement(value: doubleValue, unit: UnitLength.meters)
        }
        if let mappedValue = mappedQueryItems[CodingKeys.maximumWeight.stringValue],
           let doubleValue = Double(mappedValue)
        {
            self.maximumWeight = Measurement(value: doubleValue, unit: UnitMass.metricTons)
        }

        if let mappedValue = mappedQueryItems[CodingKeys.layers.stringValue] {
            let mappedValues = mappedValue.components(separatedBy: ";")
            var waypointsIndex = waypoints.startIndex
            for mappedValue in mappedValues {
                guard waypointsIndex < waypoints.endIndex else { break }
                waypoints[waypointsIndex].layer = Int(mappedValue) ?? nil
                waypointsIndex = waypoints.index(after: waypointsIndex)
            }
        }

        let formatter = DateFormatter.ISO8601DirectionsFormatter()
        if let mappedValue = mappedQueryItems[CodingKeys.departAt.stringValue],
           let departAt = formatter.date(from: mappedValue)
        {
            self.departAt = departAt
        }
        if let mappedValue = mappedQueryItems[CodingKeys.arriveBy.stringValue],
           let arriveBy = formatter.date(from: mappedValue)
        {
            self.arriveBy = arriveBy
        }
        if mappedQueryItems[CodingKeys.includesTollPrices.stringValue] == "true" {
            self.includesTollPrices = true
        }
        self.waypoints = waypoints
    }

#if canImport(CoreLocation)
    /// Initializes a route options object for routes between the given locations and an optional profile identifier.
    ///
    /// - Note: This initializer is intended for `CLLocation` objects created using the
    /// `CLLocation.init(latitude:longitude:)` initializer. If you intend to use a `CLLocation` object obtained from a
    /// `CLLocationManager` object, consider increasing the `horizontalAccuracy` or set it to a negative value to avoid
    /// overfitting, since the ``Waypoint`` class’s `coordinateAccuracy` property represents the maximum allowed
    /// deviation from the waypoint.
    /// - Parameters:
    ///   - locations: An array of `CLLocation` objects representing locations that the route should visit in
    /// chronological order. The array should contain at least two locations (the source and destination) and at most 25
    /// locations. Each location object is converted into a ``Waypoint`` object. This class respects the `CLLocation`
    /// class’s `coordinate` and `horizontalAccuracy` properties, converting them into the ``Waypoint`` class’s
    /// ``Waypoint/coordinate`` and ``Waypoint/coordinateAccuracy`` properties, respectively.
    ///   - profileIdentifier: A string specifying the primary mode of transportation for the routes.
    /// ``ProfileIdentifier/automobile`` is used by default.
    ///   - queryItems: URL query items to be parsed and applied as configuration to the resulting options.
    public convenience init(
        locations: [CLLocation],
        profileIdentifier: ProfileIdentifier? = nil,
        queryItems: [URLQueryItem]? = nil
    ) {
        let waypoints = locations.map { Waypoint(location: $0) }
        self.init(waypoints: waypoints, profileIdentifier: profileIdentifier, queryItems: queryItems)
    }
#endif

    /// Initializes a route options object for routes between the given geographic coordinates and an optional profile
    /// identifier.
    /// - Parameters:
    ///   - coordinates: An array of geographic coordinates representing locations that the route should visit in
    /// chronological order. The array should contain at least two locations (the source and destination) and at most 25
    /// locations. Each coordinate is converted into a ``Waypoint`` object.
    ///   - profileIdentifier: A string specifying the primary mode of transportation for the routes.
    /// ``ProfileIdentifier/automobile`` is used by default.
    ///   - queryItems: URL query items to be parsed and applied as configuration to the resulting options.
    public convenience init(
        coordinates: [LocationCoordinate2D],
        profileIdentifier: ProfileIdentifier? = nil,
        queryItems: [URLQueryItem]? = nil
    ) {
        let waypoints = coordinates.map { Waypoint(coordinate: $0) }
        self.init(waypoints: waypoints, profileIdentifier: profileIdentifier, queryItems: queryItems)
    }

    private enum CodingKeys: String, CodingKey {
        case allowsUTurnAtWaypoint = "continue_straight"
        case includesAlternativeRoutes = "alternatives"
        case includesExitRoundaboutManeuver = "roundabout_exits"
        case roadClassesToAvoid = "exclude"
        case roadClassesToAllow = "include"
        case refreshingEnabled = "enable_refresh"
        case initialManeuverAvoidanceRadius = "avoid_maneuver_radius"
        case maximumHeight = "max_height"
        case maximumWidth = "max_width"
        case maximumWeight = "max_weight"
        case alleyPriority = "alley_bias"
        case walkwayPriority = "walkway_bias"
        case speed = "walking_speed"
        case waypointTargets = "waypoint_targets"
        case arriveBy = "arrive_by"
        case departAt = "depart_at"
        case layers
        case includesTollPrices = "compute_toll_cost"
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(allowsUTurnAtWaypoint, forKey: .allowsUTurnAtWaypoint)
        try container.encode(includesAlternativeRoutes, forKey: .includesAlternativeRoutes)
        try container.encode(includesExitRoundaboutManeuver, forKey: .includesExitRoundaboutManeuver)
        try container.encode(roadClassesToAvoid, forKey: .roadClassesToAvoid)
        try container.encode(roadClassesToAllow, forKey: .roadClassesToAllow)
        try container.encode(refreshingEnabled, forKey: .refreshingEnabled)
        try container.encodeIfPresent(initialManeuverAvoidanceRadius, forKey: .initialManeuverAvoidanceRadius)
        try container.encodeIfPresent(maximumHeight?.converted(to: .meters).value, forKey: .maximumHeight)
        try container.encodeIfPresent(maximumWidth?.converted(to: .meters).value, forKey: .maximumWidth)
        try container.encodeIfPresent(maximumWeight?.converted(to: .metricTons).value, forKey: .maximumWeight)
        try container.encodeIfPresent(alleyPriority, forKey: .alleyPriority)
        try container.encodeIfPresent(walkwayPriority, forKey: .walkwayPriority)
        try container.encodeIfPresent(speed, forKey: .speed)

        let formatter = DateFormatter.ISO8601DirectionsFormatter()
        if let arriveBy {
            try container.encode(formatter.string(from: arriveBy), forKey: .arriveBy)
        }
        if let departAt {
            try container.encode(formatter.string(from: departAt), forKey: .departAt)
        }

        if includesTollPrices {
            try container.encode(includesTollPrices, forKey: .includesTollPrices)
        }
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.allowsUTurnAtWaypoint = try container.decode(Bool.self, forKey: .allowsUTurnAtWaypoint)

        self.includesAlternativeRoutes = try container.decode(Bool.self, forKey: .includesAlternativeRoutes)

        self.includesExitRoundaboutManeuver = try container.decode(Bool.self, forKey: .includesExitRoundaboutManeuver)

        self.roadClassesToAvoid = try container.decode(RoadClasses.self, forKey: .roadClassesToAvoid)

        self.roadClassesToAllow = try container.decode(RoadClasses.self, forKey: .roadClassesToAllow)

        self.refreshingEnabled = try container.decode(Bool.self, forKey: .refreshingEnabled)

        self._initialManeuverAvoidanceRadius = try container.decodeIfPresent(
            LocationDistance.self,
            forKey: .initialManeuverAvoidanceRadius
        )

        if let maximumHeightValue = try container.decodeIfPresent(Double.self, forKey: .maximumHeight) {
            self.maximumHeight = Measurement(value: maximumHeightValue, unit: .meters)
        }

        if let maximumWidthValue = try container.decodeIfPresent(Double.self, forKey: .maximumWidth) {
            self.maximumWidth = Measurement(value: maximumWidthValue, unit: .meters)
        }
        if let maximumWeightValue = try container.decodeIfPresent(Double.self, forKey: .maximumWeight) {
            self.maximumWeight = Measurement(value: maximumWeightValue, unit: .metricTons)
        }

        self.alleyPriority = try container.decodeIfPresent(DirectionsPriority.self, forKey: .alleyPriority)

        self.walkwayPriority = try container.decodeIfPresent(DirectionsPriority.self, forKey: .walkwayPriority)

        self.speed = try container.decodeIfPresent(LocationSpeed.self, forKey: .speed)

        let formatter = DateFormatter.ISO8601DirectionsFormatter()
        if let dateString = try container.decodeIfPresent(String.self, forKey: .departAt) {
            self.departAt = formatter.date(from: dateString)
        }

        if let dateString = try container.decodeIfPresent(String.self, forKey: .arriveBy) {
            self.arriveBy = formatter.date(from: dateString)
        }

        self.includesTollPrices = try container.decodeIfPresent(Bool.self, forKey: .includesTollPrices) ?? false

        try super.init(from: decoder)
    }

    /// Initializes an equivalent route options object from a match options object. Desirable for building a navigation
    /// experience from map matching.
    ///
    /// - Parameter matchOptions: The ``MatchOptions`` that is being used to convert to a ``RouteOptions`` object.
    public convenience init(matchOptions: MatchOptions) {
        self.init(waypoints: matchOptions.waypoints, profileIdentifier: matchOptions.profileIdentifier)
        self.includesSteps = matchOptions.includesSteps
        self.shapeFormat = matchOptions.shapeFormat
        self.attributeOptions = matchOptions.attributeOptions
        self.routeShapeResolution = matchOptions.routeShapeResolution
        self.locale = matchOptions.locale
        self.includesSpokenInstructions = matchOptions.includesSpokenInstructions
        self.includesVisualInstructions = matchOptions.includesVisualInstructions
    }

    override var abridgedPath: String {
        return "directions/v5/\(profileIdentifier.rawValue)"
    }

    // MARK: Influencing the Path of the Route

    /// A Boolean value that indicates whether a returned route may require a point U-turn at an intermediate waypoint.
    ///
    /// If the value of this property is `true`, a returned route may require an immediate U-turn at an intermediate
    /// waypoint. At an intermediate waypoint, if the value of this property is `false`, each returned route may
    /// continue straight ahead or turn to either side but may not U-turn. This property has no effect if only two
    /// waypoints are specified.
    ///
    /// Set this property to `true` if you expect the user to traverse each leg of the trip separately. For example, it
    /// would be quite easy for the user to effectively “U-turn” at a waypoint if the user first parks the car and
    /// patronizes a restaurant there before embarking on the next leg of the trip. Set this property to `false` if you
    /// expect the user to proceed to the next waypoint immediately upon arrival. For example, if the user only needs to
    /// drop off a passenger or package at the waypoint before continuing, it would be inconvenient to perform a U-turn
    /// at that location.
    ///
    /// The default value of this property is `false` when the profile identifier is ``ProfileIdentifier/automobile`` or
    /// ``ProfileIdentifier/automobileAvoidingTraffic`` and `true` otherwise.
    open var allowsUTurnAtWaypoint: Bool

    /// The route classes that the calculated routes will avoid.
    ///
    /// Currently, you can only specify a single road class to avoid.
    open var roadClassesToAvoid: RoadClasses = []

    /// The route classes that the calculated routes will allow.
    ///
    /// This property has no effect unless the profile identifier is set to ``ProfileIdentifier/automobile`` or
    /// ``ProfileIdentifier/automobileAvoidingTraffic``
    open var roadClassesToAllow: RoadClasses = []

    /// The number that influences whether the route should prefer or avoid alleys or narrow service roads between
    /// buildings.
    /// If this property isn't explicitly set, the Directions API will choose the most reasonable value.
    ///
    /// This property has no effect unless the profile identifier is set to ``ProfileIdentifier/automobile`` or
    /// ``ProfileIdentifier/walking``.
    ///
    /// The value of this property must be at least ``DirectionsPriority/low`` and at most ``DirectionsPriority/high``.
    /// ``DirectionsPriority/medium`` neither prefers nor avoids alleys, while a negative value between
    /// ``DirectionsPriority/low`` and ``DirectionsPriority/medium`` avoids alleys, and a positive value between
    /// ``DirectionsPriority/medium`` and ``DirectionsPriority/high`` prefers alleys. A value of 0.9 is suitable for
    /// pedestrians who are comfortable with walking down alleys.
    open var alleyPriority: DirectionsPriority?

    /// The number that influences whether the route should prefer or avoid roads or paths that are set aside for
    /// pedestrian-only use (walkways or footpaths).
    /// If this property isn't explicitly set, the Directions API will choose the most reasonable value.
    ///
    /// This property has no effect unless the profile identifier is set to ``ProfileIdentifier/walking``. You can
    /// adjust this property to avoid [sidewalks and crosswalks that are mapped as separate
    /// footpaths](https://wiki.openstreetmap.org/wiki/Sidewalks#Sidewalk_as_separate_way), which may be more granular
    /// than needed for some forms of pedestrian navigation.
    ///
    /// The value of this property must be at least ``DirectionsPriority/low`` and at most ``DirectionsPriority/high``.
    /// ``DirectionsPriority/medium`` neither prefers nor avoids walkways, while a negative value between
    /// ``DirectionsPriority/low`` and ``DirectionsPriority/medium`` avoids walkways, and a positive value between
    /// ``DirectionsPriority/medium`` and ``DirectionsPriority/high`` prefers walkways. A value of −0.1 results in less
    /// verbose routes in cities where sidewalks and crosswalks are generally mapped as separate footpaths.
    open var walkwayPriority: DirectionsPriority?

    /// The expected uniform travel speed measured in meters per second.
    /// If this property isn't explicitly set, the Directions API will choose the most reasonable value.
    ///
    /// This property has no effect unless the profile identifier is set to ``ProfileIdentifier/walking``. You can
    /// adjust this property to account for running or for faster or slower gaits. When the profile identifier is set to
    /// another profile identifier, such as ``ProfileIdentifier/automobile`, this property is ignored in favor of the
    /// expected travel speed on each road along the route. This property may be supported by other routing profiles in
    /// the future.
    ///
    /// The value of this property must be at least `CLLocationSpeed.minimumWalking` and at most
    /// `CLLocationSpeed.maximumWalking`. `CLLocationSpeed.normalWalking` corresponds to a typical preferred walking
    /// speed.
    open var speed: LocationSpeed?

    /// The desired arrival time, ignoring seconds precision, in the local time at the route destination.
    ///
    /// This property has no effect unless the profile identifier is set to ``ProfileIdentifier/automobile``.
    open var arriveBy: Date?

    /// The desired departure time, ignoring seconds precision, in the local time at the route origin
    ///
    /// This property has no effect unless the profile identifier is set to ``ProfileIdentifier/automobile`` or
    /// ``ProfileIdentifier/automobileAvoidingTraffic``.
    open var departAt: Date?

    // MARK: Specifying the Response Format

    /// A Boolean value indicating whether alternative routes should be included in the response.
    ///
    /// If the value of this property is `false`, the server only calculates a single route that visits each of the
    /// waypoints. If the value of this property is `true`, the server attempts to find additional reasonable routes
    /// that visit the waypoints. Regardless, multiple routes are only returned if it is possible to visit the waypoints
    /// by a different route without significantly increasing the distance or travel time. The alternative routes may
    /// partially overlap with the preferred route, especially if intermediate waypoints are specified.
    ///
    /// Alternative routes may take longer to calculate and make the response significantly larger, so only request
    /// alternative routes if you intend to display them to the user or let the user choose them over the preferred
    /// route. For example, do not request alternative routes if you only want to know the distance or estimated travel
    /// time to a destination.
    ///
    /// The default value of this property is `false`.
    open var includesAlternativeRoutes = false

    /// A Boolean value indicating whether the route includes a ``ManeuverType/exitRoundabout`` or
    /// ``ManeuverType/exitRotary`` step when traversing a roundabout or rotary, respectively.
    ///
    /// If this option is set to `true`, a route that traverses a roundabout includes both a
    /// ``ManeuverType/takeRoundabout`` step and a ``ManeuverType/exitRoundabout`` step; likewise, a route that
    /// traverses a large, named roundabout includes both a ``ManeuverType/takeRotary`` step and a
    /// ``ManeuverType/exitRotary`` step. Otherwise, it only includes a ``ManeuverType/takeRoundabout`` or
    /// ``ManeuverType/takeRotary`` step. This option is set to `false` by default.
    open var includesExitRoundaboutManeuver = false

    /// A Boolean value indicating whether `Directions` can refresh time-dependent properties of the ``RouteLeg``s of
    /// the resulting ``Route``s.
    ///
    /// To refresh the ``RouteLeg/expectedSegmentTravelTimes``, ``RouteLeg/segmentSpeeds``, and
    /// ``RouteLeg/segmentCongestionLevels`` properties, use the
    /// `Directions.refreshRoute(responseIdentifier:routeIndex:fromLegAtIndex:completionHandler:)` method. This property
    /// is ignored unless ``DirectionsOptions/profileIdentifier`` is ``ProfileIdentifier/automobileAvoidingTraffic``.
    /// This option is set
    /// to `false` by default.
    open var refreshingEnabled = false

    /// The maximum vehicle height.
    ///
    /// If this parameter is provided, `Directions` will compute a route that includes only roads with a height limit
    /// greater than or equal to the max vehicle height or no height limit.
    ///
    /// This property is supported by ``ProfileIdentifier/automobile`` and
    /// ``ProfileIdentifier/automobileAvoidingTraffic`` profiles.
    /// The value must be between 0 and 10 when converted to meters.
    open var maximumHeight: Measurement<UnitLength>?

    /// The maximum vehicle width.
    ///
    /// If this parameter is provided, `Directions` will compute a route that includes only roads with a width limit
    /// greater than or equal to the max vehicle width or no width limit.
    /// This property is supported by   ``ProfileIdentifier/automobile`` and
    /// ``ProfileIdentifier/automobileAvoidingTraffic`` profiles.
    ///  The value must be between 0 and 10 when converted to meters.
    open var maximumWidth: Measurement<UnitLength>?

    /// The maximum vehicle weight.
    ///
    /// If this parameter is provided, the `Directions` will compute a route that includes only roads with a weight
    /// limit greater than or equal to the max vehicle weight.
    /// This property is supported by ``ProfileIdentifier/automobile`` and
    /// ``ProfileIdentifier/automobileAvoidingTraffic`` profiles.
    /// The value must be between 0 and 100 metric tons. If unspecified,  2.5 metric tons is assumed.
    open var maximumWeight: Measurement<UnitMass>?
    /// A radius around the starting point in which the API will avoid returning any significant maneuvers.
    ///
    /// Use this option when the vehicle is traveling at a significant speed to avoid dangerous maneuvers when
    /// re-routing. If a route is not found using the specified value, it will be ignored. Note that if a large radius
    /// is used, the API may ignore an important turn and return a long straight path before the first maneuver.
    ///
    /// This value is clamped to `LocationDistance.minimumManeuverIgnoringRadius` and
    /// `LocationDistance.maximumManeuverIgnoringRadius`.
    open var initialManeuverAvoidanceRadius: LocationDistance? {
        get {
            _initialManeuverAvoidanceRadius
        }
        set {
            _initialManeuverAvoidanceRadius = newValue.map {
                min(
                    LocationDistance.maximumManeuverIgnoringRadius,
                    max(
                        LocationDistance.minimumManeuverIgnoringRadius,
                        $0
                    )
                )
            }
        }
    }

    private var _initialManeuverAvoidanceRadius: LocationDistance?

    /// Toggle whether to return calculated toll cost for the route, if data is available.
    ///
    /// Toll prices are populeted in resulting route's ``Route/tollPrices``.
    /// Default value is `false`.
    open var includesTollPrices = false

    // MARK: Getting the Request URL

    override open var urlQueryItems: [URLQueryItem] {
        var params: [URLQueryItem] = [
            URLQueryItem(
                name: CodingKeys.includesAlternativeRoutes.stringValue,
                value: includesAlternativeRoutes.queryString
            ),
            URLQueryItem(
                name: CodingKeys.allowsUTurnAtWaypoint.stringValue,
                value: (!allowsUTurnAtWaypoint).queryString
            ),
        ]

        if includesExitRoundaboutManeuver {
            params.append(URLQueryItem(
                name: CodingKeys.includesExitRoundaboutManeuver.stringValue,
                value: includesExitRoundaboutManeuver.queryString
            ))
        }
        if let alleyPriority = alleyPriority?.rawValue {
            params.append(URLQueryItem(name: CodingKeys.alleyPriority.stringValue, value: String(alleyPriority)))
        }

        if let walkwayPriority = walkwayPriority?.rawValue {
            params.append(URLQueryItem(name: CodingKeys.walkwayPriority.stringValue, value: String(walkwayPriority)))
        }

        if let speed {
            params.append(URLQueryItem(name: CodingKeys.speed.stringValue, value: String(speed)))
        }

        if !roadClassesToAvoid.isEmpty {
            let roadClasses = roadClassesToAvoid.description
            params.append(URLQueryItem(name: CodingKeys.roadClassesToAvoid.stringValue, value: roadClasses))
        }

        if !roadClassesToAllow.isEmpty {
            let parameterValue = roadClassesToAllow.description
            params.append(URLQueryItem(name: CodingKeys.roadClassesToAllow.stringValue, value: parameterValue))
        }

        if refreshingEnabled, profileIdentifier == .automobileAvoidingTraffic {
            params.append(URLQueryItem(
                name: CodingKeys.refreshingEnabled.stringValue,
                value: refreshingEnabled.queryString
            ))
        }

        if waypoints.first(where: { $0.targetCoordinate != nil }) != nil {
            let targetCoordinates = waypoints.filter(\.separatesLegs)
                .map { $0.targetCoordinate?.requestDescription ?? "" }.joined(separator: ";")
            params.append(URLQueryItem(name: CodingKeys.waypointTargets.stringValue, value: targetCoordinates))
        }

        if waypoints.contains(where: { $0.layer != nil }) {
            let layers = waypoints.map { $0.layer?.description ?? "" }.joined(separator: ";")
            params.append(URLQueryItem(name: CodingKeys.layers.stringValue, value: layers))
        }

        if let initialManeuverAvoidanceRadius {
            params.append(URLQueryItem(
                name: CodingKeys.initialManeuverAvoidanceRadius.stringValue,
                value: String(initialManeuverAvoidanceRadius)
            ))
        }

        if let maximumHeight {
            let heightInMeters = maximumHeight.converted(to: .meters).value
            params.append(URLQueryItem(name: CodingKeys.maximumHeight.stringValue, value: String(heightInMeters)))
        }

        if let maximumWidth {
            let widthInMeters = maximumWidth.converted(to: .meters).value
            params.append(URLQueryItem(name: CodingKeys.maximumWidth.stringValue, value: String(widthInMeters)))
        }

        if let maximumWeight {
            let weightInTonnes = maximumWeight.converted(to: .metricTons).value
            params.append(URLQueryItem(name: CodingKeys.maximumWeight.stringValue, value: String(weightInTonnes)))
        }

        if [ProfileIdentifier.automobile, .automobileAvoidingTraffic].contains(profileIdentifier) {
            let formatter = DateFormatter.ISO8601DirectionsFormatter()

            if let departAt {
                params.append(URLQueryItem(
                    name: CodingKeys.departAt.stringValue,
                    value: String(formatter.string(from: departAt))
                ))
            }

            if profileIdentifier == .automobile,
               let arriveBy
            {
                params.append(URLQueryItem(
                    name: CodingKeys.arriveBy.stringValue,
                    value: String(formatter.string(from: arriveBy))
                ))
            }
        }

        if includesTollPrices {
            params.append(URLQueryItem(
                name: CodingKeys.includesTollPrices.stringValue,
                value: includesTollPrices.queryString
            ))
        }

        return params + super.urlQueryItems
    }
}

@available(*, unavailable)
extension RouteOptions: @unchecked Sendable {}

extension Bool {
    var queryString: String {
        return self ? "true" : "false"
    }
}

extension LocationSpeed {
    /// Pedestrians are assumed to walk at an average rate of 1.42 meters per second (5.11 kilometers per hour or 3.18
    /// miles per hour), corresponding to a typical preferred walking speed.
    static let normalWalking: LocationSpeed = 1.42

    /// Pedestrians are assumed to walk no slower than 0.14 meters per second (0.50 kilometers per hour or 0.31 miles
    /// per hour) on average.
    static let minimumWalking: LocationSpeed = 0.14

    /// Pedestrians are assumed to walk no faster than 6.94 meters per second (25.0 kilometers per hour or 15.5 miles
    /// per hour) on average.
    static let maximumWalking: LocationSpeed = 6.94
}

extension LocationDistance {
    /// Minimum positive value to ignore maneuvers around origin point during routing.
    static let minimumManeuverIgnoringRadius: LocationDistance = 1

    /// Maximum value to ignore maneuvers around origin point during routing.
    static let maximumManeuverIgnoringRadius: LocationDistance = 1000
}

extension DateFormatter {
    /// Special ISO8601 date converter for `depart_at` and `arrive_by` parameters, as Directions API explicitly require
    /// no seconds bit.
    fileprivate static func ISO8601DirectionsFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }
}
