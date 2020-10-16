import Foundation
import MapboxDirections
import Turf

/**
 `RouteProgress` stores the user’s progress along a route.
 */
open class RouteProgress: Codable {
    private static let reroutingAccuracy: CLLocationAccuracy = 90
    
    var indexedRoute: IndexedRoute

    /**
     Returns the current `Route`.
     */
    public var route: Route {
        return indexedRoute.0
    }
    
    public let routeOptions: RouteOptions

    /**
     Index representing current `RouteLeg`.
     */
    public var legIndex: Int {
        didSet {
            assert(legIndex >= 0 && legIndex < route.legs.endIndex)
            // TODO: Set stepIndex to 0 or last index based on whether leg index was incremented or decremented.
            currentLegProgress = RouteLegProgress(leg: currentLeg)
            
            legIndexHandler?(oldValue, legIndex)
        }
    }
    typealias LegIndexHandlerAction = (_ oldValue: Int, _ newValue: Int) -> ()
    var legIndexHandler: LegIndexHandlerAction?
    /**
     If waypoints are provided in the `Route`, this will contain which leg the user is on.
     */
    public var currentLeg: RouteLeg {
        return route.legs[legIndex]
    }

    /**
     Returns the remaining legs left on the current route
     */
    public var remainingLegs: [RouteLeg] {
        return Array(route.legs.suffix(from: legIndex + 1))
    }

    /**
     Returns the remaining steps left on the current route
     */
    public var remainingSteps: [RouteStep] {
        return currentLegProgress.remainingSteps + remainingLegs.flatMap { $0.steps }
    }
    
    /**
     Returns true if `currentLeg` is the last leg.
     */
    public var isFinalLeg: Bool {
        guard let lastLeg = route.legs.last else { return false }
        return currentLeg == lastLeg
    }

    /**
     Total distance traveled by user along all legs.
     */
    public var distanceTraveled: CLLocationDistance {
        return route.legs.prefix(upTo: legIndex).map { $0.distance }.reduce(0, +) + currentLegProgress.distanceTraveled
    }

    /**
     Total seconds remaining on all legs.
     */
    public var durationRemaining: TimeInterval {
        return route.legs.suffix(from: legIndex + 1).map { $0.expectedTravelTime }.reduce(0, +) + currentLegProgress.durationRemaining
    }

    /**
     Number between 0 and 1 representing how far along the `Route` the user has traveled.
     */
    public var fractionTraveled: Double {
        return distanceTraveled / route.distance
    }

    /**
     Total distance remaining in meters along route.
     */
    public var distanceRemaining: CLLocationDistance {
        return route.distance - distanceTraveled
    }

    /**
     The waypoints remaining on the current route.
     
     This property does not include waypoints whose `Waypoint.separatesLegs` property is set to `false`.
     */
    public var remainingWaypoints: [Waypoint] {
        return route.legs.suffix(from: legIndex).compactMap { $0.destination }
    }
    
    /**
     The waypoints remaining on the current route, including any waypoints that do not separate legs.
     */
    func remainingWaypointsForCalculatingRoute() -> [Waypoint] {
        let (currentLegViaPoints, remainingWaypoints) = routeOptions.waypoints(fromLegAt: legIndex)
        let currentLegRemainingViaPoints = currentLegProgress.remainingWaypoints(among: currentLegViaPoints)
        return currentLegRemainingViaPoints + remainingWaypoints
    }

    /**
     Returns the progress along the current `RouteLeg`.
     */
    public var currentLegProgress: RouteLegProgress
    
    public var priorLeg: RouteLeg? {
        return legIndex > 0 ? route.legs[legIndex - 1] : nil
    }
    
    /**
     The step prior to the current step along this route.
     
     The prior step may be part of a different RouteLeg than the current step. If the current step is the first step along the route, this property is set to nil.
     */
    public var priorStep: RouteStep? {
        return currentLegProgress.priorStep ?? priorLeg?.steps.last
    }
    
    /**
     The leg following the current leg along this route.
     
     If this leg is the last leg of the route, this property is set to nil.
     */
    public var upcomingLeg: RouteLeg? {
        return legIndex + 1 < route.legs.endIndex ? route.legs[legIndex + 1] : nil
    }
    
    /**
     The step following the current step along this route.
     
     The upcoming step may be part of a different RouteLeg than the current step. If it is the last step along the route, this property is set to nil.
     */
    public var upcomingStep: RouteStep? {
        return currentLegProgress.upcomingStep ?? upcomingLeg?.steps.first
    }
    
    /**
     Upcoming `RouteAlerts` as reported by the navigation engine.
     
     Contents of the array depends on user's current progress along the route and are modified on each location update. Array always contains only events, that user stil not passed. Keep in mind that some events may have non-zero length and are also incleded while user is mid-traversing it. You can use this to get info about incoming POIs.
     */
    public internal(set) var upcomingRouteAlerts: [UpcomingRouteAlertInfo] = []
    
    /**
     Returns an array of `CLLocationCoordinate2D` of the coordinates along the current step and any adjacent steps.
     
     - important: The adjacent steps may be part of legs other than the current leg.
     */
    public var nearbyShape: LineString {
        let priorCoordinates = priorStep?.shape?.coordinates.dropLast() ?? []
        let currentShape = currentLegProgress.currentStep.shape
        let upcomingCoordinates = upcomingStep?.shape?.coordinates.dropFirst() ?? []
        if let currentShape = currentShape, priorCoordinates.isEmpty && upcomingCoordinates.isEmpty {
            return currentShape
        }
        return LineString(priorCoordinates + (currentShape?.coordinates ?? []) + upcomingCoordinates)
    }
    
    /**
     Tuple containing a `CongestionLevel` and a corresponding `TimeInterval` representing the expected travel time for this segment.
     */
    public typealias TimedCongestionLevel = (CongestionLevel, TimeInterval)

    /**
     If the route contains both `segmentCongestionLevels` and `expectedSegmentTravelTimes`, this property is set to a deeply nested array of `TimeCongestionLevels` per segment per step per leg.
     */
    public private(set) var congestionTravelTimesSegmentsByStep: [[[TimedCongestionLevel]]] = []

    /**
     An dictionary containing a `TimeInterval` total per `CongestionLevel`. Only `CongestionLevel` founnd on that step will present. Broken up by leg and then step.
     */
    public private(set) var congestionTimesPerStep: [[[CongestionLevel: TimeInterval]]]  = [[[:]]]

    /**
     Intializes a new `RouteProgress`.

     - parameter route: The route to follow.
     - parameter routeIndex: The index of the route in the `RouteResponse`. By default, the route is the first route in the response.
     - parameter legIndex: Zero-based index indicating the current leg the user is on.
     */
    public init(route: Route, routeIndex: Int, options: RouteOptions, legIndex: Int = 0, spokenInstructionIndex: Int = 0) {
        self.indexedRoute = (route, routeIndex)
        self.routeOptions = options
        self.legIndex = legIndex
        self.currentLegProgress = RouteLegProgress(leg: route.legs[legIndex], stepIndex: 0, spokenInstructionIndex: spokenInstructionIndex)

        self.calculateLegsCongestion()
    }

    public var averageCongestionLevelRemainingOnLeg: CongestionLevel? {
        guard let coordinates = currentLegProgress.currentStepProgress.step.shape?.coordinates else {
            return .unknown
        }
        
        let coordinatesLeftOnStepCount = Int(floor((Double(coordinates.count)) * currentLegProgress.currentStepProgress.fractionTraveled))

        guard coordinatesLeftOnStepCount >= 0 else { return .unknown }

        guard legIndex < congestionTravelTimesSegmentsByStep.count,
            currentLegProgress.stepIndex < congestionTravelTimesSegmentsByStep[legIndex].count else { return .unknown }

        let congestionTimesForStep = congestionTravelTimesSegmentsByStep[legIndex][currentLegProgress.stepIndex]
        guard coordinatesLeftOnStepCount <= congestionTimesForStep.count else { return .unknown }

        let remainingCongestionTimesForStep = congestionTimesForStep.suffix(from: coordinatesLeftOnStepCount)
        let remainingCongestionTimesForRoute = congestionTimesPerStep[legIndex].suffix(from: currentLegProgress.stepIndex + 1)

        var remainingStepCongestionTotals: [CongestionLevel: TimeInterval] = [:]
        for stepValues in remainingCongestionTimesForRoute {
            for (key, value) in stepValues {
                remainingStepCongestionTotals[key] = (remainingStepCongestionTotals[key] ?? 0) + value
            }
        }

        for (segmentCongestion, segmentTime) in remainingCongestionTimesForStep {
            remainingStepCongestionTotals[segmentCongestion] = (remainingStepCongestionTotals[segmentCongestion] ?? 0) + segmentTime
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

    func reroutingOptions(with current: CLLocation) -> RouteOptions {
        let oldOptions = routeOptions
        let user = Waypoint(coordinate: current.coordinate)

        if (current.course >= 0) {
            user.heading = current.course
            user.headingAccuracy = RouteProgress.reroutingAccuracy
        }
        let newWaypoints = [user] + remainingWaypointsForCalculatingRoute()
        let newOptions = oldOptions.copy() as! RouteOptions
        newOptions.waypoints = newWaypoints

        return newOptions
    }
    
    func calculateLegsCongestion() {
        congestionTimesPerStep.removeAll()
        congestionTravelTimesSegmentsByStep.removeAll()
        
        for (legIndex, leg) in route.legs.enumerated() {
            var maneuverCoordinateIndex = 0

            congestionTimesPerStep.append([])

            /// An index into the route’s coordinates and congestionTravelTimesSegmentsByStep that corresponds to a step’s maneuver location.
            var congestionTravelTimesSegmentsByLeg: [[TimedCongestionLevel]] = []

            if let segmentCongestionLevels = leg.segmentCongestionLevels, let expectedSegmentTravelTimes = leg.expectedSegmentTravelTimes {
                for step in leg.steps {
                    guard let coordinates = step.shape?.coordinates else { continue }
                    let stepCoordinateCount = step.maneuverType == .arrive ? Int(coordinates.count) : coordinates.dropLast().count
                    let nextManeuverCoordinateIndex = maneuverCoordinateIndex + stepCoordinateCount - 1

                    guard nextManeuverCoordinateIndex < segmentCongestionLevels.count else { continue }
                    guard nextManeuverCoordinateIndex < expectedSegmentTravelTimes.count else { continue }

                    let stepSegmentCongestionLevels = Array(segmentCongestionLevels[maneuverCoordinateIndex..<nextManeuverCoordinateIndex])
                    let stepSegmentTravelTimes = Array(expectedSegmentTravelTimes[maneuverCoordinateIndex..<nextManeuverCoordinateIndex])
                    maneuverCoordinateIndex = nextManeuverCoordinateIndex

                    let stepTimedCongestionLevels = Array(zip(stepSegmentCongestionLevels, stepSegmentTravelTimes))
                    congestionTravelTimesSegmentsByLeg.append(stepTimedCongestionLevels)
                    var stepCongestionValues: [CongestionLevel: TimeInterval] = [:]
                    for (segmentCongestion, segmentTime) in stepTimedCongestionLevels {
                        stepCongestionValues[segmentCongestion] = (stepCongestionValues[segmentCongestion] ?? 0) + segmentTime
                    }

                    congestionTimesPerStep[legIndex].append(stepCongestionValues)
                }
            }

            congestionTravelTimesSegmentsByStep.append(congestionTravelTimesSegmentsByLeg)
        }
    }
    
    /**
     Updates the current route with attributes from the given skeletal route.
     */
    public func refreshRoute(with refreshedRoute: RefreshedRoute, at location: CLLocation) {
        route.refreshLegAttributes(from: refreshedRoute)
        currentLegProgress = RouteLegProgress(leg: route.legs[legIndex],
                                              stepIndex: currentLegProgress.stepIndex,
                                              spokenInstructionIndex: currentLegProgress.currentStepProgress.spokenInstructionIndex)
        calculateLegsCongestion()
        updateDistanceTraveled(with: location)
    }
    
    /**
     Increments the progress according to new location specified.
     - parameter location: Updated user location.
     */
    public func updateDistanceTraveled(with location: CLLocation) {
        let stepProgress = currentLegProgress.currentStepProgress
        let step = stepProgress.step
        
        //Increment the progress model
        guard let polyline = step.shape else {
            preconditionFailure("Route steps used for navigation must have shape data")
        }
        if let closestCoordinate = polyline.closestCoordinate(to: location.coordinate) {
            let remainingDistance = polyline.distance(from: closestCoordinate.coordinate)!
            let distanceTraveled = step.distance - remainingDistance
            stepProgress.distanceTraveled = distanceTraveled
        }
    }
    
    // MARK: - Codable implementation
    
    private enum CodingKeys: String, CodingKey {
        case indexedRoute
        case indexedRouteIndex
        case routeOptions
        case legIndex
        case currentLegProgress
    }
        
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let route = try container.decode(Route.self, forKey: .indexedRoute)
        let routeIndex = try container.decode(Int.self, forKey: .indexedRouteIndex)
        self.indexedRoute = (route, routeIndex)
        self.routeOptions = try container.decode(RouteOptions.self, forKey: .routeOptions)
        self.legIndex = try container.decode(Int.self, forKey: .legIndex)
        self.currentLegProgress = try container.decode(RouteLegProgress.self, forKey: .currentLegProgress)
        
        calculateLegsCongestion()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(indexedRoute.0, forKey: .indexedRoute)
        try container.encode(indexedRoute.1, forKey: .indexedRouteIndex)
        try container.encode(routeOptions, forKey: .routeOptions)
        try container.encode(legIndex, forKey: .legIndex)
        try container.encode(currentLegProgress, forKey: .currentLegProgress)
    }
}
