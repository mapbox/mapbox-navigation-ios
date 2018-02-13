import Foundation
import MapboxDirections
import Turf

/**
 `RouteProgress` stores the user’s progress along a route.
 */
@objc(MBRouteProgress)
open class RouteProgress: NSObject {
    /**
     Returns the current `Route`.
     */
    @objc public let route: Route

    /**
     Index representing current `RouteLeg`.
     */
    @objc public var legIndex: Int {
        didSet {
            assert(legIndex >= 0 && legIndex < route.legs.endIndex)
            // TODO: Set stepIndex to 0 or last index based on whether leg index was incremented or decremented.
            currentLegProgress = RouteLegProgress(leg: currentLeg)
        }
    }

    /**
     If waypoints are provided in the `Route`, this will contain which leg the user is on.
     */
    @objc public var currentLeg: RouteLeg {
        return route.legs[legIndex]
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
    @objc public var distanceTraveled: CLLocationDistance {
        return route.legs.prefix(upTo: legIndex).map { $0.distance }.reduce(0, +) + currentLegProgress.distanceTraveled
    }

    /**
     Total seconds remaining on all legs.
     */
    @objc public var durationRemaining: TimeInterval {
        return route.legs.suffix(from: legIndex + 1).map { $0.expectedTravelTime }.reduce(0, +) + currentLegProgress.durationRemaining
    }
    
    /**
     Number between 0 and 1 representing how far along the `Route` the user has traveled.
     */
    @objc public var fractionTraveled: Double {
        return distanceTraveled / route.distance
    }

    /**
     Total distance remaining in meters along route.
     */
    @objc public var distanceRemaining: CLLocationDistance {
        return route.distance - distanceTraveled
    }
    
    /**
     Number of waypoints remaining on the current route.
     */
    @objc public var remainingWaypoints: [Waypoint] {
        return route.legs.suffix(from: legIndex).map { $0.destination }
    }
    
    /**
     Returns the progress along the current `RouteLeg`.
     */
    @objc public var currentLegProgress: RouteLegProgress!
    
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
    @objc public init(route: Route, legIndex: Int = 0, spokenInstructionIndex: Int = 0) {
        self.route = route
        self.legIndex = legIndex
        super.init()
        currentLegProgress = RouteLegProgress(leg: currentLeg, stepIndex: 0, spokenInstructionIndex: spokenInstructionIndex)
        
        for (legIndex, leg) in route.legs.enumerated() {
            var maneuverCoordinateIndex = 0
            
            congestionTimesPerStep.append([])
            
            /// An index into the route’s coordinates and congestionTravelTimesSegmentsByStep that corresponds to a step’s maneuver location.
            var congestionTravelTimesSegmentsByLeg: [[TimedCongestionLevel]] = []
            
            if let segmentCongestionLevels = leg.segmentCongestionLevels, let expectedSegmentTravelTimes = leg.expectedSegmentTravelTimes {
                
                for step in leg.steps {
                    guard let coordinates = step.coordinates else { continue }
                    let stepCoordinateCount = step.maneuverType == .arrive ? Int(step.coordinateCount) : coordinates.dropLast().count
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
}

/**
 `RouteLegProgress` stores the user’s progress along a route leg.
 */
@objc(MBRouteLegProgress)
open class RouteLegProgress: NSObject {
    /**
     Returns the current `RouteLeg`.
     */
    @objc public let leg: RouteLeg
    
    /**
     Index representing the current step.
     */
    @objc public var stepIndex: Int {
        didSet {
            assert(stepIndex >= 0 && stepIndex < leg.steps.endIndex)
            currentStepProgress = RouteStepProgress(step: currentStep)
        }
    }
    
    /**
     The remaining steps for user to complete.
     */
    @objc public var remainingSteps: [RouteStep] {
        return Array(leg.steps.suffix(from: stepIndex + 1))
    }

    /**
     Total distance traveled in meters along current leg.
     */
    @objc public var distanceTraveled: CLLocationDistance {
        return leg.steps.prefix(upTo: stepIndex).map { $0.distance }.reduce(0, +) + currentStepProgress.distanceTraveled
    }
    
    /**
     Duration remaining in seconds on current leg.
     */
    @objc public var durationRemaining: TimeInterval {
        return remainingSteps.map { $0.expectedTravelTime }.reduce(0, +) + currentStepProgress.durationRemaining
    }

    /**
     Number between 0 and 1 representing how far along the current leg the user has traveled.
     */
    @objc public var fractionTraveled: Double {
        return distanceTraveled / leg.distance
    }
    
    @objc public var userHasArrivedAtWaypoint = false
    
    /**
     Returns the `RouteStep` before a given step. Returns `nil` if there is no step prior.
     */
    @objc public func stepBefore(_ step: RouteStep) -> RouteStep? {
        guard let index = leg.steps.index(of: step) else {
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
    @objc public func stepAfter(_ step: RouteStep) -> RouteStep? {
        guard let index = leg.steps.index(of: step) else {
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
    @objc public var priorStep: RouteStep? {
        guard stepIndex - 1 >= 0 else {
            return nil
        }
        return leg.steps[stepIndex - 1]
    }
    
    /**
     Returns the current `RouteStep` for the leg the user is on.
     */
    @objc public var currentStep: RouteStep {
        return leg.steps[stepIndex]
    }

    /**
     Returns the upcoming `RouteStep`.
     
     If there is no `upcomingStep`, nil is returned.
     */
    @objc public var upComingStep: RouteStep? {
        guard stepIndex + 1 < leg.steps.endIndex else {
            return nil
        }
        return leg.steps[stepIndex + 1]
    }

    /**
     Returns step 2 steps ahead.
     
     If there is no `followOnStep`, nil is returned.
     */
    @objc public var followOnStep: RouteStep? {
        guard stepIndex + 2 < leg.steps.endIndex else {
            return nil
        }
        return leg.steps[stepIndex + 2]
    }

    /**
     Return bool whether step provided is the current `RouteStep` the user is on.
     */
    @objc public func isCurrentStep(_ step: RouteStep) -> Bool {
        return step == currentStep
    }
    
    /**
     Returns the progress along the current `RouteStep`.
     */
    @objc public var currentStepProgress: RouteStepProgress

    /**
     Intializes a new `RouteLegProgress`.
     
     - parameter leg: Leg on a `Route`.
     - parameter stepIndex: Current step the user is on.
     */
    @objc public init(leg: RouteLeg, stepIndex: Int = 0, spokenInstructionIndex: Int = 0) {
        self.leg = leg
        self.stepIndex = stepIndex
        currentStepProgress = RouteStepProgress(step: leg.steps[stepIndex], spokenInstructionIndex: spokenInstructionIndex)
    }
    
    /**
     Returns an array of `CLLocationCoordinate2D` of the prior, current and upcoming step geometry.
     */
    @objc public var nearbyCoordinates: [CLLocationCoordinate2D] {
        let priorCoords = priorStep?.coordinates ?? []
        let upcomingCoords = upComingStep?.coordinates ?? []
        let currentCoords = currentStep.coordinates ?? []
        let nearby = priorCoords + currentCoords + upcomingCoords
        assert(!nearby.isEmpty, "Step must have coordinates")
        return nearby
    }
    
    typealias StepIndexDistance = (index: Int, distance: CLLocationDistance)
    
    func closestStep(to coordinate: CLLocationCoordinate2D) -> StepIndexDistance? {
        var currentClosest: StepIndexDistance?
        let remainingSteps = leg.steps.suffix(from: stepIndex)
        
        for (currentStepIndex, step) in remainingSteps.enumerated() {
            guard let coords = step.coordinates else { continue }
            guard let closestCoordOnStep = Polyline(coords).closestCoordinate(to: coordinate) else { continue }
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
}

/**
 `RouteStepProgress` stores the user’s progress along a route step.
 */
@objc(MBRouteStepProgress)
open class RouteStepProgress: NSObject {

    /**
     Returns the current `RouteStep`.
     */
    @objc public let step: RouteStep

    /**
     Returns distance user has traveled along current step.
     */
    @objc public var distanceTraveled: CLLocationDistance = 0
    
    /**
     Returns distance from user to end of step.
     */
    @objc public var userDistanceToManeuverLocation: CLLocationDistance = Double.infinity
    
    /**
     Total distance in meters remaining on current step.
     */
    @objc public var distanceRemaining: CLLocationDistance {
        return step.distance - distanceTraveled
    }

    /**
     Number between 0 and 1 representing fraction of current step traveled.
     */
    @objc public var fractionTraveled: Double {
        guard step.distance > 0 else { return 1 }
        return distanceTraveled / step.distance
    }

    /**
     Number of seconds remaining on current step.
     */
    @objc public var durationRemaining: TimeInterval {
        return (1 - fractionTraveled) * step.expectedTravelTime
    }

    /**
     Intializes a new `RouteStepProgress`.
     
     - parameter step: Step on a `RouteLeg`.
     */
    @objc public init(step: RouteStep, spokenInstructionIndex: Int = 0) {
        self.step = step
        self.intersectionIndex = 0
        self.spokenInstructionIndex = spokenInstructionIndex
    }
    
    /**
     All intersections on the current `RouteStep` and also the first intersection on the upcoming `RouteStep`.
     
     The upcoming `RouteStep` first `Intersection` is added because it is omitted from the current step.
     */
    @objc public var intersectionsIncludingUpcomingManeuverIntersection: [Intersection]?
    
    /**
     The next intersection the user will travel through.
     
     The step must contains `Intersections` for this value not be `nil`.
     */
    @objc public var upcomingIntersection: Intersection? {
        guard let intersections = intersectionsIncludingUpcomingManeuverIntersection, intersectionIndex + 1 < intersections.endIndex else {
            return nil
        }
        
        return intersections[intersectionIndex]
    }
    
    /**
     Index representing the current intersection.
     */
    @objc public var intersectionIndex: Int = 0
    
    /**
     The distance in meters the user is to the next intersection they will pass through.
     */
    public var userDistanceToUpcomingIntersection: CLLocationDistance?
    
    /**
     Index into `step.instructionsSpokenAlongStep` representing the current spoken instruction.
     */
    @objc public var spokenInstructionIndex: Int = 0
    
    
    /**
     An `Array` of remaining `SpokenInstruction` for a step.
     */
    @objc public var remainingSpokenInstructions: [SpokenInstruction]? {
        guard let instructions = step.instructionsSpokenAlongStep else { return nil }
        return Array(instructions.suffix(from: spokenInstructionIndex))
    }
    
    /**
     Current Instruction for the user's progress along a step.
     */
    @objc public var currentSpokenInstruction: SpokenInstruction? {
        guard let instructionsSpokenAlongStep = step.instructionsSpokenAlongStep else { return nil }
        guard spokenInstructionIndex < instructionsSpokenAlongStep.count else { return nil }
        return instructionsSpokenAlongStep[spokenInstructionIndex]
    }
}
