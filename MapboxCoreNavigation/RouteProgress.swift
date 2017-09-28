import Foundation
import MapboxDirections


/**
 An `AlertLevel` indicates the user’s general progress toward a step’s maneuver point. A change to the current alert level is often an opportunity to present the user with a visual or voice notification about the upcoming maneuver.
 */
@objc(MBAlertLevel)
public enum AlertLevel: Int {
    
    /**
     Default `AlertLevel`
     */
    case none
    
    
    /**
     The user has started the route.
     */
    case depart
    
    
    /**
     The user has recently completed a step.
     */
    case low
    
    
    /**
     The user is approaching the maneuver.
     */
    case medium
    
    
    /**
     The user is at or very close to the maneuver point
     */
    case high
    
    
    /**
     The user has completed the route.
     */
    case arrive
}


/**
 `RouteProgress` stores the user’s progress along a route.
 */
@objc(MBRouteProgress)
open class RouteProgress: NSObject {
    /**
     Returns the current `Route`.
     */
    public let route: Route

    /**
     Index representing current `RouteLeg`.
     */
    public var legIndex: Int {
        didSet {
            assert(legIndex >= 0 && legIndex < route.legs.endIndex)
            // TODO: Set stepIndex to 0 or last index based on whether leg index was incremented or decremented.
            currentLegProgress.alertUserLevel = .none
            currentLegProgress = RouteLegProgress(leg: currentLeg)
        }
    }


    /**
     If waypoints are provided in the `Route`, this will contain which leg the user is on.
     */
    public var currentLeg: RouteLeg {
        return route.legs[legIndex]
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
     Number of waypoints remaining on the current route.
     */
    public var remainingWaypoints: [Waypoint] {
        return route.legs.suffix(from: legIndex).map { $0.destination }
    }
    
    /**
     Returns the progress along the current `RouteLeg`.
     */
    public var currentLegProgress: RouteLegProgress!
    
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
     - parameter alertLevel: Optional `AlertLevel` to start the `RouteProgress` at.
     */
    public init(route: Route, legIndex: Int = 0, alertLevel: AlertLevel = .none) {
        self.route = route
        self.legIndex = legIndex
        super.init()
        currentLegProgress = RouteLegProgress(leg: currentLeg, stepIndex: 0, alertLevel: alertLevel)
        
        for (legIndex, leg) in route.legs.enumerated() {
            var maneuverCoordinateIndex = 0
            
            congestionTimesPerStep.append([])
            
            /// An index into the route’s coordinates and congestionTravelTimesSegmentsByStep that corresponds to a step’s maneuver location.
            var congestionTravelTimesSegmentsByLeg: [[TimedCongestionLevel]] = []
            
            if let segmentCongestionLevels = leg.segmentCongestionLevels, let expectedSegmentTravelTimes = leg.expectedSegmentTravelTimes  {
                
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
     Total distance traveled in meters along current leg.
     */
    public var distanceTraveled: CLLocationDistance {
        return leg.steps.prefix(upTo: stepIndex).map { $0.distance }.reduce(0, +) + currentStepProgress.distanceTraveled
    }
    
    
    /**
     Duration remaining in seconds on current leg.
     */
    public var durationRemaining: TimeInterval {
        return leg.steps.suffix(from: stepIndex + 1).map { $0.expectedTravelTime }.reduce(0, +) + currentStepProgress.durationRemaining
    }


    /**
     Number between 0 and 1 representing how far along the current leg the user has traveled.
     */
    public var fractionTraveled: Double {
        return distanceTraveled / leg.distance
    }

    /**
     `AlertLevel` for the current step.
     */
    public var alertUserLevel: AlertLevel = .none

    
    /**
     Returns the `RouteStep` before a given step. Returns `nil` if there is no step prior.
     */
    public func stepBefore(_ step: RouteStep) -> RouteStep? {
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
    public func stepAfter(_ step: RouteStep) -> RouteStep? {
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
    public var upComingStep: RouteStep? {
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
     - parameter alertLevel: Optional `AlertLevel` to start the `RouteProgress` at.
     */
    public init(leg: RouteLeg, stepIndex: Int = 0, alertLevel: AlertLevel = .none) {
        self.leg = leg
        self.stepIndex = stepIndex
        self.alertUserLevel = alertLevel
        currentStepProgress = RouteStepProgress(step: leg.steps[stepIndex])
    }
    
    
    /**
     Returns an array of `CLLocationCoordinate2D` of the prior, current and upcoming step geometry.
     */
    public var nearbyCoordinates: [CLLocationCoordinate2D] {
        let priorCoords = priorStep?.coordinates ?? []
        let upcomingCoords = upComingStep?.coordinates ?? []
        let currentCoords = currentStep.coordinates ?? []
        let nearby = priorCoords + currentCoords + upcomingCoords
        assert(!nearby.isEmpty, "Step must have coordinates")
        return nearby
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
    public let step: RouteStep


    /**
     Returns distance user has traveled along current step.
     */
    public var distanceTraveled: CLLocationDistance = 0
    
    
    /**
     Returns distance from user to end of step.
     */
    public var userDistanceToManeuverLocation: CLLocationDistance = Double.infinity
    
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
    public init(step: RouteStep) {
        self.step = step
        self.intersectionIndex = 0
    }
    
    /**
     All intersections on the current `RouteStep` and also the first intersection on the upcoming `RouteStep`.
     
     The upcoming `RouteStep` first `Intersection` is added because it is omitted from the current step.
     */
    public var intersectionsIncludingUpcomingManeuverIntersection: [Intersection]?
    
    /**
     The next intersection the user will travel through.
     
     The step must contains `Intersections` for this value not be `nil`.
     */
    public var upcomingIntersection: Intersection? {
        guard let intersections = intersectionsIncludingUpcomingManeuverIntersection, intersectionIndex + 1 < intersections.endIndex else {
            return nil
        }
        
        return intersections[intersectionIndex]
    }
    
    /**
     Index representing the current intersection.
     */
    public var intersectionIndex: Int = 0
    
    
    /**
     The distance in meters the user is to the next intersection they will pass through.
     */
    public var userDistanceToUpcomingIntersection: CLLocationDistance?
}
