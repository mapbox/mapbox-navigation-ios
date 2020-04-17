import Foundation
import MapboxDirections
import Turf

/**
 `RouteProgress` stores the user’s progress along a route.
 */
open class RouteProgress {
    private static let reroutingAccuracy: CLLocationAccuracy = 90

    /**
     Returns the current `Route`.
     */
    public let route: Route
    
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
    public var congestionTravelTimesSegmentsByStep: [[[TimedCongestionLevel]]] = []

    /**
     An dictionary containing a `TimeInterval` total per `CongestionLevel`. Only `CongestionLevel` founnd on that step will present. Broken up by leg and then step.
     */
    public var congestionTimesPerStep: [[[CongestionLevel: TimeInterval]]]  = [[[:]]]

    /**
     Intializes a new `RouteProgress`.

     - parameter route: The route to follow.
     - parameter legIndex: Zero-based index indicating the current leg the user is on.
     */
    public init(route: Route, options: RouteOptions, legIndex: Int = 0, spokenInstructionIndex: Int = 0) {
        self.route = route
        self.routeOptions = options
        self.legIndex = legIndex
        self.currentLegProgress = RouteLegProgress(leg: route.legs[legIndex], stepIndex: 0, spokenInstructionIndex: spokenInstructionIndex)

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
}

/**
 `RouteLegProgress` stores the user’s progress along a route leg.
 */
open class RouteLegProgress {
    /**
     Returns the current `RouteLeg`.
     */
    public let leg: RouteLeg

    /**
     Index representing the current step.
     */
    public var stepIndex: Int {
        didSet {
            assert(stepIndex >= 0 && stepIndex < leg.steps.endIndex)
            currentStepProgress = RouteStepProgress(step: currentStep)
        }
    }

    /**
     The remaining steps for user to complete.
     */
    public var remainingSteps: [RouteStep] {
        return Array(leg.steps.suffix(from: stepIndex + 1))
    }

    /**
     Total distance traveled in meters along current leg.
     */
    public var distanceTraveled: CLLocationDistance {
        return leg.steps.prefix(upTo: stepIndex).map { $0.distance }.reduce(0, +) + currentStepProgress.distanceTraveled
    }

    /**
     Duration remaining in seconds on current leg.
     */
    public var durationRemaining: TimeInterval {
        return remainingSteps.map { $0.expectedTravelTime }.reduce(0, +) + currentStepProgress.durationRemaining
    }

    /**
     Distance remaining on the current leg.
     */
    public var distanceRemaining: CLLocationDistance {
        return remainingSteps.map { $0.distance }.reduce(0, +) + currentStepProgress.distanceRemaining
    }

    /**
     Number between 0 and 1 representing how far along the current leg the user has traveled.
     */
    public var fractionTraveled: Double {
        return distanceTraveled / leg.distance
    }

    public var userHasArrivedAtWaypoint = false

    /**
     Returns the `RouteStep` before a given step. Returns `nil` if there is no step prior.
     */
    public func stepBefore(_ step: RouteStep) -> RouteStep? {
        guard let index = leg.steps.firstIndex(of: step) else {
            return nil
        }
        if index > 0 {
            return leg.steps[index-1]
        }
        return nil
    }

    /**
     Returns the `RouteStep` after a given step. Returns `nil` if there is not a step after.
     */
    public func stepAfter(_ step: RouteStep) -> RouteStep? {
        guard let index = leg.steps.firstIndex(of: step) else {
            return nil
        }
        if index+1 < leg.steps.endIndex {
            return leg.steps[index+1]
        }
        return nil
    }

    /**
     Returns the `RouteStep` before the current step.

     If there is no `priorStep`, nil is returned.
     */
    public var priorStep: RouteStep? {
        guard stepIndex - 1 >= 0 else {
            return nil
        }
        return leg.steps[stepIndex - 1]
    }

    /**
     Returns the current `RouteStep` for the leg the user is on.
     */
    public var currentStep: RouteStep {
        return leg.steps[stepIndex]
    }

    /**
     Returns the upcoming `RouteStep`.

     If there is no `upcomingStep`, nil is returned.
     */
    @available(swift, obsoleted: 0.1, renamed: "upcomingStep")
    public var upComingStep: RouteStep? {
        fatalError()
    }
    
    public var upcomingStep: RouteStep? {
        guard stepIndex + 1 < leg.steps.endIndex else {
            return nil
        }
        return leg.steps[stepIndex + 1]
    }

    /**
     Returns step 2 steps ahead.

     If there is no `followOnStep`, nil is returned.
     */
    public var followOnStep: RouteStep? {
        guard stepIndex + 2 < leg.steps.endIndex else {
            return nil
        }
        return leg.steps[stepIndex + 2]
    }

    /**
     Return bool whether step provided is the current `RouteStep` the user is on.
     */
    public func isCurrentStep(_ step: RouteStep) -> Bool {
        return step == currentStep
    }

    /**
     Returns the progress along the current `RouteStep`.
     */
    public var currentStepProgress: RouteStepProgress

    /**
     Intializes a new `RouteLegProgress`.

     - parameter leg: Leg on a `Route`.
     - parameter stepIndex: Current step the user is on.
     */
    public init(leg: RouteLeg, stepIndex: Int = 0, spokenInstructionIndex: Int = 0) {
        self.leg = leg
        self.stepIndex = stepIndex
        currentStepProgress = RouteStepProgress(step: leg.steps[stepIndex], spokenInstructionIndex: spokenInstructionIndex)
    }

    typealias StepIndexDistance = (index: Int, distance: CLLocationDistance)

    func closestStep(to coordinate: CLLocationCoordinate2D) -> StepIndexDistance? {
        var currentClosest: StepIndexDistance?
        let remainingSteps = leg.steps.suffix(from: stepIndex)

        for (currentStepIndex, step) in remainingSteps.enumerated() {
            guard let shape = step.shape else { continue }
            guard let closestCoordOnStep = shape.closestCoordinate(to: coordinate) else { continue }
            let foundIndex = currentStepIndex + stepIndex

            // First time around, currentClosest will be `nil`.
            guard let currentClosestDistance = currentClosest?.distance else {
                currentClosest = (index: foundIndex, distance: closestCoordOnStep.distance)
                continue
            }

            if closestCoordOnStep.distance < currentClosestDistance {
                currentClosest = (index: foundIndex, distance: closestCoordOnStep.distance)
            }
        }

        return currentClosest
    }
    
    /**
     The waypoints remaining on the current leg, not including the leg’s destination.
     */
    func remainingWaypoints(among waypoints: [Waypoint]) -> [Waypoint] {
        guard waypoints.count > 1 else {
            // The leg has only a source and no via points. Save ourselves a call to RouteLeg.coordinates, which can be expensive.
            return []
        }
        let legPolyline = leg.shape
        guard let userCoordinateIndex = legPolyline.indexedCoordinateFromStart(distance: distanceTraveled)?.index else {
            // The leg is empty, so none of the waypoints are meaningful.
            return []
        }
        var slice = legPolyline
        var accumulatedCoordinates = 0
        return Array(waypoints.drop { (waypoint) -> Bool in
            var newSlice = slice.sliced(from: waypoint.coordinate)
            // Work around <https://github.com/mapbox/turf-swift/pull/79>.
            if newSlice.coordinates.count > 2 && newSlice.coordinates.last == newSlice.coordinates.dropLast().last {
                newSlice.coordinates.removeLast()
            }
            accumulatedCoordinates += slice.coordinates.count - newSlice.coordinates.count
            slice = newSlice
            return accumulatedCoordinates <= userCoordinateIndex
        })
    }

    /**
     Returns the SpeedLimit for the current position along the route. Returns SpeedLimit.invalid if the speed limit is unknown or missing.
     
     The maximum speed may be an advisory speed limit for segments where legal limits are not posted, such as highway entrance and exit ramps. If the speed limit along a particular segment is unknown, it is set to `nil`. If the speed is unregulated along the segment, such as on the German _Autobahn_ system, it is represented by a measurement whose value is `Double.infinity`.
     
     Speed limit data is available in [a number of countries and territories worldwide](https://docs.mapbox.com/help/how-mapbox-works/directions/).
     */
    public var currentSpeedLimit: Measurement<UnitSpeed>? {
        guard let segmentMaximumSpeedLimits = leg.segmentMaximumSpeedLimits else {
            return nil
        }
        
        let distanceTraveled = currentStepProgress.distanceTraveled
        guard var index = currentStep.shape?.indexedCoordinateFromStart(distance: distanceTraveled)?.index else {
            return nil
        }
        
        var range = leg.segmentRangesByStep[stepIndex]
        
        // indexedCoordinateFromStart(distance:) can return a coordinate indexed to the last coordinate of the step, which is past any segment on the current step.
        if index == range.count && upcomingStep != nil {
            range = leg.segmentRangesByStep[stepIndex.advanced(by: 1)]
            index = 0
        }
        guard index < range.count && range.upperBound <= segmentMaximumSpeedLimits.endIndex else {
            return nil
        }
        
        let speedLimit = segmentMaximumSpeedLimits[range][range.lowerBound.advanced(by: index)]
        if let speedUnit = currentStep.speedLimitUnit {
            return speedLimit?.converted(to: speedUnit)
        } else {
            return speedLimit
        }
    }
}

/**
 `RouteStepProgress` stores the user’s progress along a route step.
 */
open class RouteStepProgress {
    /**
     Returns the current `RouteStep`.
     */
    public let step: RouteStep

    /**
     Returns distance user has traveled along current step.
     */
    public var distanceTraveled: CLLocationDistance = 0

    /**
     Returns distance from user to end of step.
     */
    public var userDistanceToManeuverLocation: CLLocationDistance

    /**
     Total distance in meters remaining on current step.
     */
    public var distanceRemaining: CLLocationDistance {
        return step.distance - distanceTraveled
    }

    /**
     Number between 0 and 1 representing fraction of current step traveled.
     */
    public var fractionTraveled: Double {
        guard step.distance > 0 else { return 1 }
        return distanceTraveled / step.distance
    }

    /**
     Number of seconds remaining on current step.
     */
    public var durationRemaining: TimeInterval {
        return (1 - fractionTraveled) * step.expectedTravelTime
    }
    
    /**
     Intializes a new `RouteStepProgress`.

     - parameter step: Step on a `RouteLeg`.
     */
    public init(step: RouteStep, spokenInstructionIndex: Int = 0) {
        self.step = step
        self.userDistanceToManeuverLocation = step.distance
        self.intersectionIndex = 0
        self.spokenInstructionIndex = spokenInstructionIndex
    }

    /**
     All intersections on the current `RouteStep` and also the first intersection on the upcoming `RouteStep`.

     The upcoming `RouteStep` first `Intersection` is added because it is omitted from the current step.
     */
    public var intersectionsIncludingUpcomingManeuverIntersection: [Intersection]?

    /**
     The next intersection the user will travel through.

     The step must contain `intersectionsIncludingUpcomingManeuverIntersection` otherwise this property will be `nil`.
     */
    public var upcomingIntersection: Intersection? {
        guard let intersections = intersectionsIncludingUpcomingManeuverIntersection, intersections.startIndex..<intersections.endIndex-1 ~= intersectionIndex else {
            return nil
        }

        return intersections[intersections.index(after: intersectionIndex)]
    }

    /**
     Index representing the current intersection.
     */
    public var intersectionIndex: Int = 0

    /**
     The current intersection the user will travel through.

     The step must contain `intersectionsIncludingUpcomingManeuverIntersection` otherwise this property will be `nil`.
     */
    public var currentIntersection: Intersection? {
        guard let intersections = intersectionsIncludingUpcomingManeuverIntersection, intersections.startIndex..<intersections.endIndex ~= intersectionIndex else {
            return nil
        }

        return intersections[intersectionIndex]
    }

    /**
     Returns an array of the calculated distances from the current intersection to the next intersection on the current step.
     */
    public var intersectionDistances: Array<CLLocationDistance>?

    /**
     The distance in meters the user is to the next intersection they will pass through.
     */
    public var userDistanceToUpcomingIntersection: CLLocationDistance?

    /**
     Index into `step.instructionsDisplayedAlongStep` representing the current visual instruction for the step.
     */
    public var visualInstructionIndex: Int = 0

    /**
     An `Array` of remaining `VisualInstruction` for a step.
     */
    public var remainingVisualInstructions: [VisualInstructionBanner]? {
        guard let visualInstructions = step.instructionsDisplayedAlongStep else { return nil }
        return Array(visualInstructions.suffix(from: visualInstructionIndex))
    }

    /**
     Index into `step.instructionsSpokenAlongStep` representing the current spoken instruction.
     */
    public var spokenInstructionIndex: Int = 0

    /**
     An `Array` of remaining `SpokenInstruction` for a step.
     */
    public var remainingSpokenInstructions: [SpokenInstruction]? {
        guard let instructions = step.instructionsSpokenAlongStep else { return nil }
        return Array(instructions.suffix(from: spokenInstructionIndex))
    }

    /**
     Current spoken instruction for the user's progress along a step.
     */
    public var currentSpokenInstruction: SpokenInstruction? {
        guard let instructionsSpokenAlongStep = step.instructionsSpokenAlongStep else { return nil }
        guard spokenInstructionIndex < instructionsSpokenAlongStep.count else { return nil }
        return instructionsSpokenAlongStep[spokenInstructionIndex]
    }

    /**
     Current visual instruction for the user's progress along a step.
     */
    public var currentVisualInstruction: VisualInstructionBanner? {
        guard let instructionsDisplayedAlongStep = step.instructionsDisplayedAlongStep else { return nil }
        guard visualInstructionIndex < instructionsDisplayedAlongStep.count else { return nil }
        return instructionsDisplayedAlongStep[visualInstructionIndex]
    }
    
    public var keyPathsAffectingValueForRemainingVisualInstructions: Set<String> {
        return ["step.instructionsDisplayedAlongStep", "visualInstructionIndex"]
    }
    
    public var keyPathsAffectingValueForRemainingSpokenInstructions: Set<String> {
        return ["step.instructionsDisplayedAlongStep", "spokenInstructionIndex"]
    }
}
