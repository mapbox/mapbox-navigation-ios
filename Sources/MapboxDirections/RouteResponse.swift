import Foundation
import Turf
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum ResponseOptions: Sendable {
    case route(RouteOptions)
    case match(MatchOptions)
}

@available(*, unavailable)
extension ResponseOptions: @unchecked Sendable {}

/// A ``RouteResponse`` object is a structure that corresponds to a directions response returned by the Mapbox
/// Directions API.
public struct RouteResponse: ForeignMemberContainer {
    public var foreignMembers: JSONObject = [:]

    /// The raw HTTP response from the Directions API.
    public let httpResponse: HTTPURLResponse?

    /// The unique identifier that the Mapbox Directions API has assigned to this response.
    public let identifier: String?

    /// An array of ``Route`` objects sorted from most recommended to least recommended. A route may be highly
    /// recommended
    /// based on characteristics such as expected travel time or distance.
    /// This property contains a maximum of two ``Route``s.
    public var routes: [Route]? {
        didSet {
            updateRoadClassExclusionViolations()
        }
    }

    /// An array of ``Waypoint`` objects in the order of the input coordinates. Each ``Waypoint`` is an input coordinate
    /// snapped to the road and path network.
    ///
    /// This property omits the waypoint corresponding to any waypoint in ``DirectionsOptions/waypoints`` that has
    /// ``Waypoint/separatesLegs`` set to `true`.
    public let waypoints: [Waypoint]?

    /// The criteria for the directions response.
    public let options: ResponseOptions

    /// The credentials used to make the request.
    public let credentials: Credentials

    /// The time when this ``RouteResponse`` object was created, which is immediately upon recieving the raw URL
    /// response.
    ///
    /// If you manually start fetching a task returned by `Directions.url(forCalculating:)`, this property is set to
    /// `nil`; use the `URLSessionTaskTransactionMetrics.responseEndDate` property instead. This property may also be
    /// set to `nil` if you create this result from a JSON object or encoded object.
    ///
    /// This property does not persist after encoding and decoding.
    public var created: Date = .init()

    /// A time period during which the routes from this ``RouteResponse`` are eligable for refreshing.
    ///
    /// `nil` value indicates that route refreshing is not available for related routes.
    public let refreshTTL: TimeInterval?

    /// A deadline after which  the routes from this ``RouteResponse`` are eligable for refreshing.
    ///
    /// `nil` value indicates that route refreshing is not available for related routes.
    public var refreshInvalidationDate: Date? {
        refreshTTL.map { created.addingTimeInterval($0) }
    }

    /// Managed array of ``RoadClasses`` restrictions specified to ``RouteOptions/roadClassesToAvoid`` which were
    /// violated
    /// during route calculation.
    ///
    /// Routing engine may still utilize ``RoadClasses`` meant to be avoided in cases when routing is impossible
    /// otherwise.
    ///
    /// Violations are ordered by routes from the ``routes`` array, then by a leg, step, and intersection, where
    /// ``RoadClasses`` restrictions were ignored. `nil` and empty return arrays correspond to `nil` and empty
    /// ``routes``
    /// array respectively.
    public private(set) var roadClassExclusionViolations: [RoadClassExclusionViolation]?
}

extension RouteResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case message
        case error
        case identifier = "uuid"
        case routes
        case waypoints
        case refreshTTL = "refresh_ttl"
    }

    public init(
        httpResponse: HTTPURLResponse?,
        identifier: String? = nil,
        routes: [Route]? = nil,
        waypoints: [Waypoint]? = nil,
        options: ResponseOptions,
        credentials: Credentials,
        refreshTTL: TimeInterval? = nil
    ) {
        self.httpResponse = httpResponse
        self.identifier = identifier
        self.options = options
        self.routes = routes
        self.waypoints = waypoints
        self.credentials = credentials
        self.refreshTTL = refreshTTL

        updateRoadClassExclusionViolations()
    }

    public init(matching response: MapMatchingResponse, options: MatchOptions, credentials: Credentials) throws {
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()

        decoder.userInfo[.options] = options
        decoder.userInfo[.credentials] = credentials
        encoder.userInfo[.options] = options
        encoder.userInfo[.credentials] = credentials

        var routes: [Route]?

        if let matches = response.matches {
            let matchesData = try encoder.encode(matches)
            routes = try decoder.decode([Route].self, from: matchesData)
        }

        var waypoints: [Waypoint]?

        if let tracepoints = response.tracepoints {
            let filtered = tracepoints.compactMap { $0 }
            let tracepointsData = try encoder.encode(filtered)
            waypoints = try decoder.decode([Waypoint].self, from: tracepointsData)
        }

        self.init(
            httpResponse: response.httpResponse,
            identifier: nil,
            routes: routes,
            waypoints: waypoints,
            options: .match(options),
            credentials: credentials
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.httpResponse = decoder.userInfo[.httpResponse] as? HTTPURLResponse

        guard let credentials = decoder.userInfo[.credentials] as? Credentials else {
            throw DirectionsCodingError.missingCredentials
        }

        self.credentials = credentials

        if let options = decoder.userInfo[.options] as? RouteOptions {
            self.options = .route(options)
        } else if let options = decoder.userInfo[.options] as? MatchOptions {
            self.options = .match(options)
        } else {
            throw DirectionsCodingError.missingOptions
        }

        self.identifier = try container.decodeIfPresent(String.self, forKey: .identifier)

        // Decode waypoints from the response and update their names according to the waypoints from
        // DirectionsOptions.waypoints.
        let decodedWaypoints = try container.decodeIfPresent([Waypoint?].self, forKey: .waypoints)?.compactMap { $0 }
        var optionsWaypoints: [Waypoint] = []

        switch options {
        case .match(options: let matchOpts):
            optionsWaypoints = matchOpts.waypoints
        case .route(options: let routeOpts):
            optionsWaypoints = routeOpts.waypoints
        }

        if let decodedWaypoints {
            // The response lists the same number of tracepoints as the waypoints in the request, whether or not a given
            // waypoint is leg-separating.
            var waypoints = zip(decodedWaypoints, optionsWaypoints).map { pair -> Waypoint in
                let (decodedWaypoint, waypointInOptions) = pair
                var waypoint = Waypoint(
                    coordinate: decodedWaypoint.coordinate,
                    coordinateAccuracy: waypointInOptions.coordinateAccuracy,
                    name: waypointInOptions.name?.nonEmptyString ?? decodedWaypoint.name
                )
                waypoint.snappedDistance = decodedWaypoint.snappedDistance
                waypoint.targetCoordinate = waypointInOptions.targetCoordinate
                waypoint.heading = waypointInOptions.heading
                waypoint.headingAccuracy = waypointInOptions.headingAccuracy
                waypoint.separatesLegs = waypointInOptions.separatesLegs
                waypoint.allowsArrivingOnOppositeSide = waypointInOptions.allowsArrivingOnOppositeSide

                waypoint.foreignMembers = decodedWaypoint.foreignMembers

                return waypoint
            }

            if waypoints.startIndex < waypoints.endIndex {
                waypoints[waypoints.startIndex].separatesLegs = true
            }
            let lastIndex = waypoints.endIndex - 1
            if waypoints.indices.contains(lastIndex) {
                waypoints[lastIndex].separatesLegs = true
            }

            self.waypoints = waypoints
        } else {
            self.waypoints = decodedWaypoints
        }

        if var routes = try container.decodeIfPresent([Route].self, forKey: .routes) {
            // Postprocess each route.
            for routeIndex in routes.indices {
                // Imbue each route’s legs with the waypoints refined above.
                if let waypoints {
                    routes[routeIndex].legSeparators = waypoints.filter(\.separatesLegs)
                }
            }
            self.routes = routes
        } else {
            self.routes = nil
        }

        self.refreshTTL = try container.decodeIfPresent(TimeInterval.self, forKey: .refreshTTL)

        updateRoadClassExclusionViolations()

        try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(identifier, forKey: .identifier)
        try container.encodeIfPresent(routes, forKey: .routes)
        try container.encodeIfPresent(waypoints, forKey: .waypoints)
        try container.encodeIfPresent(refreshTTL, forKey: .refreshTTL)

        try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
    }
}

extension RouteResponse {
    mutating func updateRoadClassExclusionViolations() {
        guard case .route(let routeOptions) = options else {
            roadClassExclusionViolations = nil
            return
        }

        guard let routes else {
            roadClassExclusionViolations = nil
            return
        }

        let avoidedClasses = routeOptions.roadClassesToAvoid

        guard !avoidedClasses.isEmpty else {
            roadClassExclusionViolations = nil
            return
        }

        var violations = [RoadClassExclusionViolation]()

        for (routeIndex, route) in routes.enumerated() {
            for (legIndex, leg) in route.legs.enumerated() {
                for (stepIndex, step) in leg.steps.enumerated() {
                    for (intersectionIndex, intersection) in (step.intersections ?? []).enumerated() {
                        if let outletRoadClasses = intersection.outletRoadClasses,
                           !avoidedClasses.isDisjoint(with: outletRoadClasses)
                        {
                            violations.append(RoadClassExclusionViolation(
                                roadClasses: avoidedClasses.intersection(outletRoadClasses),
                                routeIndex: routeIndex,
                                legIndex: legIndex,
                                stepIndex: stepIndex,
                                intersectionIndex: intersectionIndex
                            ))
                        }
                    }
                }
            }
        }
        roadClassExclusionViolations = violations
    }

    /// Filters ``roadClassExclusionViolations`` lazily to search for specific leg and step.
    ///
    /// - parameter routeIndex: Index of a route inside current ``RouteResponse`` to search in.
    /// - parameter legIndex: Index of a leg inside related ``Route``to search in.
    /// - returns: Lazy filtered array of ``RoadClassExclusionViolation`` under given indicies.
    ///
    /// Passing `nil` as `legIndex` will result in searching for all legs.
    public func exclusionViolations(
        routeIndex: Int,
        legIndex: Int? = nil
    ) -> LazyFilterSequence<[RoadClassExclusionViolation]> {
        return filteredViolations(
            routeIndex: routeIndex,
            legIndex: legIndex,
            stepIndex: nil,
            intersectionIndex: nil
        )
    }

    /// Filters ``roadClassExclusionViolations`` lazily to search for specific leg and step.
    ///
    /// - parameter routeIndex: Index of a route inside current ``RouteResponse`` to search in.
    /// - parameter legIndex: Index of a leg inside related ``Route``to search in.
    /// - parameter stepIndex: Index of a step inside given ``Route``'s leg.
    /// - returns: Lazy filtered array of ``RoadClassExclusionViolation`` under given indicies.
    ///
    /// Passing `nil` as `stepIndex` will result in searching for all steps.
    public func exclusionViolations(
        routeIndex: Int,
        legIndex: Int,
        stepIndex: Int? = nil
    ) -> LazyFilterSequence<[RoadClassExclusionViolation]> {
        return filteredViolations(
            routeIndex: routeIndex,
            legIndex: legIndex,
            stepIndex: stepIndex,
            intersectionIndex: nil
        )
    }

    /// Filters ``roadClassExclusionViolations`` lazily to search for specific leg, step and intersection.
    ///
    /// - parameter routeIndex: Index of a route inside current ``RouteResponse`` to search in.
    /// - parameter legIndex: Index of a leg inside related ``Route``to search in.
    /// - parameter stepIndex: Index of a step inside given ``Route``'s leg.
    /// - parameter intersectionIndex: Index of an intersection inside given ``Route``'s leg and step.
    /// - returns: Lazy filtered array of ``RoadClassExclusionViolation`` under given indicies.
    ///
    /// Passing `nil` as `intersectionIndex` will result in searching for all intersections of given step.
    public func exclusionViolations(
        routeIndex: Int,
        legIndex: Int,
        stepIndex: Int,
        intersectionIndex: Int?
    ) -> LazyFilterSequence<[RoadClassExclusionViolation]> {
        return filteredViolations(
            routeIndex: routeIndex,
            legIndex: legIndex,
            stepIndex: stepIndex,
            intersectionIndex: intersectionIndex
        )
    }

    private func filteredViolations(
        routeIndex: Int,
        legIndex: Int? = nil,
        stepIndex: Int? = nil,
        intersectionIndex: Int? = nil
    ) -> LazyFilterSequence<[RoadClassExclusionViolation]> {
        assert(
            !(stepIndex == nil && intersectionIndex != nil),
            "It is forbidden to select `intersectionIndex` without specifying `stepIndex`."
        )

        guard let roadClassExclusionViolations else {
            return LazyFilterSequence<[RoadClassExclusionViolation]>(_base: [], { _ in true })
        }

        var filtered = roadClassExclusionViolations.lazy.filter {
            $0.routeIndex == routeIndex
        }

        if let legIndex {
            filtered = filtered.filter {
                $0.legIndex == legIndex
            }
        }

        if let stepIndex {
            filtered = filtered.filter {
                $0.stepIndex == stepIndex
            }
        }

        if let intersectionIndex {
            filtered = filtered.filter {
                $0.intersectionIndex == intersectionIndex
            }
        }

        return filtered
    }
}
