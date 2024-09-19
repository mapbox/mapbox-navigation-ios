import CoreLocation
import Foundation
import MapboxDirections
import class MapboxNavigationNative.NavigationStatus
import class MapboxNavigationNative.UpcomingRouteAlert
import Turf

/// ``RouteProgress`` stores the user’s progress along a route.
public struct RouteProgress: Equatable, Sendable {
    private static let reroutingAccuracy: CLLocationAccuracy = 90

    /// Initializes a new ``RouteProgress``.
    /// - Parameters:
    ///   - navigationRoutes: The selection of routes to follow.
    ///   - waypoints: The waypoints of the routes.
    ///   - congestionConfiguration: The congestion configuration to use to display the routes.
    public init(
        navigationRoutes: NavigationRoutes,
        waypoints: [Waypoint],
        congestionConfiguration: CongestionRangesConfiguration = .default
    ) {
        self.navigationRoutes = navigationRoutes
        self.waypoints = waypoints

        self.currentLegProgress = RouteLegProgress(leg: navigationRoutes.mainRoute.route.legs[legIndex])

        self.routeAlerts = routeAlerts(from: navigationRoutes.mainRoute)
        calculateLegsCongestion(configuration: congestionConfiguration)
    }

    /// Current `RouteOptions`, optimized for rerouting.
    ///
    /// This method is useful for implementing custom rerouting. Resulting `RouteOptions` skip passed waypoints and
    /// include current user heading if possible.
    /// - Parameters:
    ///   - location: Current user location. Treated as route origin for rerouting.
    ///   - routeOptions: The initial `RouteOptions`.
    /// - Returns: Modified `RouteOptions`.
    func reroutingOptions(from location: CLLocation, routeOptions: RouteOptions) -> RouteOptions {
        let oldOptions = routeOptions
        var user = Waypoint(coordinate: location.coordinate)

        // A pedestrian can turn on a dime; there's no problem with a route that starts out by turning the pedestrian
        // around.
        let transportType = currentLegProgress.currentStep.transportType
        if transportType != .walking, location.course >= 0 {
            user.heading = location.course
            user.headingAccuracy = RouteProgress.reroutingAccuracy
        }
        let newWaypoints = [user] + remainingWaypointsForCalculatingRoute()
        let newOptions: RouteOptions
        do {
            newOptions = try oldOptions.copy()
        } catch {
            newOptions = oldOptions
        }
        newOptions.waypoints = newWaypoints

        return newOptions
    }

    // MARK: Route Statistics

    mutating func update(using status: NavigationStatus) {
        guard let activeGuidanceInfo = status.activeGuidanceInfo else {
            return
        }

        if legIndex == Int(status.legIndex) {
            currentLegProgress.update(using: status)
        } else {
            let legIndex = Int(status.legIndex)
            guard route.legs.indices.contains(legIndex) else {
                Log.info("Ignoring incorrect status update with leg index \(legIndex)", category: .navigation)
                return
            }
            var leg = RouteLegProgress(leg: route.legs[legIndex])
            leg.update(using: status)
            currentLegProgress = leg
        }

        upcomingRouteAlerts = status.upcomingRouteAlertUpdates.compactMap { routeAlert in
            routeAlerts[routeAlert.id].map {
                RouteAlert($0, distanceToStart: routeAlert.distanceToStart)
            }
        }
        shapeIndex = Int(status.geometryIndex)
        legIndex = Int(status.legIndex)

        updateDistanceToIntersection()

        distanceTraveled = activeGuidanceInfo.routeProgress.distanceTraveled
        durationRemaining = activeGuidanceInfo.routeProgress.remainingDuration
        fractionTraveled = activeGuidanceInfo.routeProgress.fractionTraveled
        distanceRemaining = activeGuidanceInfo.routeProgress.remainingDistance
    }

    mutating func updateAlternativeRoutes(using navigationRoutes: NavigationRoutes) {
        guard self.navigationRoutes.mainRoute == navigationRoutes.mainRoute,
              self.navigationRoutes.alternativeRoutes.map(\.routeId) != navigationRoutes.alternativeRoutes
                  .map(\.routeId)
        else {
            return
        }
        self.navigationRoutes = navigationRoutes
    }

    func refreshingRoute(
        with refreshedRoutes: NavigationRoutes,
        legIndex: Int,
        legShapeIndex: Int,
        congestionConfiguration: CongestionRangesConfiguration
    ) -> RouteProgress {
        var refreshedRouteProgress = self

        refreshedRouteProgress.routeAlerts = routeAlerts(from: refreshedRoutes.mainRoute)

        refreshedRouteProgress.navigationRoutes = refreshedRoutes

        refreshedRouteProgress.currentLegProgress = refreshedRouteProgress.currentLegProgress
            .refreshingLeg(with: refreshedRouteProgress.route.legs[legIndex])
        refreshedRouteProgress.calculateLegsCongestion(configuration: congestionConfiguration)

        return refreshedRouteProgress
    }

    public let waypoints: [Waypoint]

    /// Total distance traveled by user along all legs.
    public private(set) var distanceTraveled: CLLocationDistance = 0

    /// Total seconds remaining on all legs.
    public private(set) var durationRemaining: TimeInterval = 0

    /// Number between 0 and 1 representing how far along the `Route` the user has traveled.
    public private(set) var fractionTraveled: Double = 0

    /// Total distance remaining in meters along route.
    public private(set) var distanceRemaining: CLLocationDistance = 0

    /// The waypoints remaining on the current route.
    ///
    /// This property does not include waypoints whose `Waypoint.separatesLegs` property is set to `false`.
    public var remainingWaypoints: [Waypoint] {
        return route.legs.suffix(from: legIndex).compactMap(\.destination)
    }

    func waypoints(fromLegAt legIndex: Int) -> ([Waypoint], [Waypoint]) {
        // The first and last waypoints always separate legs. Make exceptions for these waypoints instead of modifying
        // them by side effect.
        let legSeparators = waypoints.filterKeepingFirstAndLast { $0.separatesLegs }
        let viaPointsByLeg = waypoints.splitExceptAtStartAndEnd(omittingEmptySubsequences: false) { $0.separatesLegs }
            .dropFirst() // No leg precedes first separator.

        let reconstitutedWaypoints = zip(legSeparators, viaPointsByLeg).dropFirst(legIndex).map { [$0.0] + $0.1 }
        let legWaypoints = reconstitutedWaypoints.first ?? []
        let subsequentWaypoints = reconstitutedWaypoints.dropFirst()
        return (legWaypoints, subsequentWaypoints.flatMap { $0 })
    }

    /// The waypoints remaining on the current route, including any waypoints that do not separate legs.
    func remainingWaypointsForCalculatingRoute() -> [Waypoint] {
        let (currentLegViaPoints, remainingWaypoints) = waypoints(fromLegAt: legIndex)
        let currentLegRemainingViaPoints = currentLegProgress.remainingWaypoints(among: currentLegViaPoints)
        return currentLegRemainingViaPoints + remainingWaypoints
    }

    /// Upcoming ``RouteAlert``s as reported by the navigation engine.
    ///
    /// The contents of the array depend on user's current progress along the route and are modified on each location
    /// update. This array contains only the alerts that the user has not passed. Some events may have non-zero length
    /// and are also included while the user is traversing it. You can use this property to get information about
    /// incoming points of interest.
    public private(set) var upcomingRouteAlerts: [RouteAlert] = []
    private(set) var routeAlerts: [String: UpcomingRouteAlert] = [:]

    private func routeAlerts(from navigationRoute: NavigationRoute) -> [String: UpcomingRouteAlert] {
        return navigationRoute.nativeRoute.getRouteInfo().alerts.reduce(into: [:]) { partialResult, alert in
            partialResult[alert.roadObject.id] = alert
        }
    }

    /// Returns an array of `CLLocationCoordinate2D` of the coordinates along the current step and any adjacent steps.
    ///
    ///  - Important: The adjacent steps may be part of legs other than the current leg.
    public var nearbyShape: LineString {
        let priorCoordinates = priorStep?.shape?.coordinates.dropLast() ?? []
        let currentShape = currentLegProgress.currentStep.shape
        let upcomingCoordinates = upcomingStep?.shape?.coordinates.dropFirst() ?? []
        if let currentShape, priorCoordinates.isEmpty, upcomingCoordinates.isEmpty {
            return currentShape
        }
        return LineString(priorCoordinates + (currentShape?.coordinates ?? []) + upcomingCoordinates)
    }

    // MARK: Updating the RouteProgress

    /// Returns the current ``NavigationRoutes``.
    public private(set) var navigationRoutes: NavigationRoutes

    /// Returns the current main `Route`.
    public var route: Route {
        navigationRoutes.mainRoute.route
    }

    public var routeId: RouteId {
        navigationRoutes.mainRoute.routeId
    }

    /// Index relative to route shape, representing the point the user is currently located at.
    public private(set) var shapeIndex: Int = 0

    /// Update the distance to intersection according to new location specified.
    private mutating func updateDistanceToIntersection() {
        guard var intersections = currentLegProgress.currentStepProgress.step.intersections else { return }

        // The intersections array does not include the upcoming maneuver intersection.
        if let upcomingIntersection = currentLegProgress.upcomingStep?.intersections?.first {
            intersections += [upcomingIntersection]
        }
        currentLegProgress.currentStepProgress.update(intersectionsIncludingUpcomingManeuverIntersection: intersections)

        if let shape = currentLegProgress.currentStep.shape,
           let upcomingIntersection = currentLegProgress.currentStepProgress.upcomingIntersection,
           let coordinateOnStep = shape.coordinateFromStart(
               distance: currentLegProgress.currentStepProgress.distanceTraveled
           )
        {
            currentLegProgress.currentStepProgress.userDistanceToUpcomingIntersection = shape.distance(
                from: coordinateOnStep,
                to: upcomingIntersection.location
            )
        }
    }

    // MARK: Leg Statistics

    /// Index representing current ``RouteLeg``.
    public private(set) var legIndex: Int = 0

    /// If waypoints are provided in the `Route`, this will contain which leg the user is on.
    public var currentLeg: RouteLeg {
        return route.legs[legIndex]
    }

    /// Returns the remaining legs left on the current route
    public var remainingLegs: [RouteLeg] {
        return Array(route.legs.suffix(from: legIndex + 1))
    }

    /// Returns true if ``currentLeg`` is the last leg.
    public var isFinalLeg: Bool {
        guard let lastLeg = route.legs.last else { return false }
        return currentLeg == lastLeg
    }

    /// Returns the progress along the current ``RouteLeg``.
    public var currentLegProgress: RouteLegProgress

    /// The previous leg.
    public var priorLeg: RouteLeg? {
        return legIndex > 0 ? route.legs[legIndex - 1] : nil
    }

    /// The leg following the current leg along this route.
    ///
    /// If this leg is the last leg of the route, this property is set to nil.
    public var upcomingLeg: RouteLeg? {
        return legIndex + 1 < route.legs.endIndex ? route.legs[legIndex + 1] : nil
    }

    // MARK: Step Statistics

    /// Returns the remaining steps left on the current route
    public var remainingSteps: [RouteStep] {
        return currentLegProgress.remainingSteps + remainingLegs.flatMap(\.steps)
    }

    /// The step prior to the current step along this route.
    ///
    /// The prior step may be part of a different RouteLeg than the current step. If the current step is the first step
    /// along the route, this property is set to nil.
    public var priorStep: RouteStep? {
        return currentLegProgress.priorStep ?? priorLeg?.steps.last
    }

    /// The step following the current step along this route.
    ///
    /// The upcoming step may be part of a different ``RouteLeg`` than the current step. If it is the last step along
    /// the route, this property is set to nil.
    public var upcomingStep: RouteStep? {
        return currentLegProgress.upcomingStep ?? upcomingLeg?.steps.first
    }

    // MARK: Leg Attributes

    /// The struc containing a ``CongestionLevel`` and a corresponding `TimeInterval` representing the expected travel
    /// time for this segment.
    public struct TimedCongestionLevel: Equatable, Sendable {
        public var level: CongestionLevel
        public var timeInterval: TimeInterval
    }

    /// If the route contains both `RouteLeg.segmentCongestionLevels` and `RouteLeg.expectedSegmentTravelTimes`, this
    /// property is set
    /// to a deeply nested array of ``RouteProgress/TimedCongestionLevel`` per segment per step per leg.
    public private(set) var congestionTravelTimesSegmentsByStep: [[[TimedCongestionLevel]]] = []

    /// An dictionary containing a `TimeInterval` total per ``CongestionLevel``. Only ``CongestionLevel`` found on that
    /// step will present. Broken up by leg and then step.
    public private(set) var congestionTimesPerStep: [[[CongestionLevel: TimeInterval]]] = [[[:]]]

    public var averageCongestionLevelRemainingOnLeg: CongestionLevel? {
        guard let coordinates = currentLegProgress.currentStepProgress.step.shape?.coordinates else {
            return .unknown
        }

        let coordinatesLeftOnStepCount =
            Int(floor(Double(coordinates.count) * currentLegProgress.currentStepProgress.fractionTraveled))

        guard coordinatesLeftOnStepCount >= 0 else { return .unknown }

        guard legIndex < congestionTravelTimesSegmentsByStep.count,
              currentLegProgress.stepIndex < congestionTravelTimesSegmentsByStep[legIndex].count
        else { return .unknown }

        let congestionTimesForStep = congestionTravelTimesSegmentsByStep[legIndex][currentLegProgress.stepIndex]
        guard coordinatesLeftOnStepCount <= congestionTimesForStep.count else { return .unknown }

        let remainingCongestionTimesForStep = congestionTimesForStep.suffix(from: coordinatesLeftOnStepCount)
        let remainingCongestionTimesForRoute = congestionTimesPerStep[legIndex]
            .suffix(from: currentLegProgress.stepIndex + 1)

        var remainingStepCongestionTotals: [CongestionLevel: TimeInterval] = [:]
        for stepValues in remainingCongestionTimesForRoute {
            for (key, value) in stepValues {
                remainingStepCongestionTotals[key] = (remainingStepCongestionTotals[key] ?? 0) + value
            }
        }

        for remainingCongestionTimeForStep in remainingCongestionTimesForStep {
            let segmentCongestion = remainingCongestionTimeForStep.level
            let segmentTime = remainingCongestionTimeForStep.timeInterval
            remainingStepCongestionTotals[segmentCongestion] = (remainingStepCongestionTotals[segmentCongestion] ?? 0) +
                segmentTime
        }

        if durationRemaining < 60 {
            return .unknown
        } else {
            if let max = remainingStepCongestionTotals.max(by: { a, b in a.value < b.value }) {
                return max.key
            } else {
                return .unknown
            }
        }
    }

    mutating func calculateLegsCongestion(configuration: CongestionRangesConfiguration) {
        congestionTimesPerStep.removeAll()
        congestionTravelTimesSegmentsByStep.removeAll()

        for (legIndex, leg) in route.legs.enumerated() {
            var maneuverCoordinateIndex = 0

            congestionTimesPerStep.append([])

            /// An index into the route’s coordinates and congestionTravelTimesSegmentsByStep that corresponds to a
            /// step’s maneuver location.
            var congestionTravelTimesSegmentsByLeg: [[TimedCongestionLevel]] = []

            if let segmentCongestionLevels = leg.resolveCongestionLevels(using: configuration),
               let expectedSegmentTravelTimes = leg.expectedSegmentTravelTimes
            {
                for step in leg.steps {
                    guard let coordinates = step.shape?.coordinates else { continue }
                    let stepCoordinateCount = step.maneuverType == .arrive ? Int(coordinates.count) : coordinates
                        .dropLast().count
                    let nextManeuverCoordinateIndex = maneuverCoordinateIndex + stepCoordinateCount - 1

                    guard nextManeuverCoordinateIndex < segmentCongestionLevels.count else { continue }
                    guard nextManeuverCoordinateIndex < expectedSegmentTravelTimes.count else { continue }

                    let stepSegmentCongestionLevels =
                        Array(segmentCongestionLevels[maneuverCoordinateIndex..<nextManeuverCoordinateIndex])
                    let stepSegmentTravelTimes =
                        Array(expectedSegmentTravelTimes[maneuverCoordinateIndex..<nextManeuverCoordinateIndex])
                    maneuverCoordinateIndex = nextManeuverCoordinateIndex

                    let stepTimedCongestionLevels = Array(
                        zip(stepSegmentCongestionLevels, stepSegmentTravelTimes)
                            .map {
                                TimedCongestionLevel(level: $0, timeInterval: $1)
                            }
                    )
                    congestionTravelTimesSegmentsByLeg.append(stepTimedCongestionLevels)
                    var stepCongestionValues: [CongestionLevel: TimeInterval] = [:]
                    for stepTimedCongestionLevel in stepTimedCongestionLevels {
                        let segmentCongestion = stepTimedCongestionLevel.level
                        let segmentTime = stepTimedCongestionLevel.timeInterval
                        stepCongestionValues[segmentCongestion] = (stepCongestionValues[segmentCongestion] ?? 0) +
                            segmentTime
                    }

                    congestionTimesPerStep[legIndex].append(stepCongestionValues)
                }
            }

            congestionTravelTimesSegmentsByStep.append(congestionTravelTimesSegmentsByLeg)
        }
    }

    public var routeIsComplete: Bool {
        return isFinalLeg && currentLegProgress
            .userHasArrivedAtWaypoint && currentLegProgress.distanceRemaining <= 3
    }
}

extension UpcomingRouteAlert: @unchecked Sendable {}
