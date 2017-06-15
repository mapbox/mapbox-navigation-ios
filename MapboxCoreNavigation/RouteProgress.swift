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
    public let route: Route

    /**
     Index representing current leg
     */
    public var legIndex: Int {
        didSet {
            assert(legIndex >= 0 && legIndex < route.legs.endIndex)
            // TODO: Set stepIndex to 0 or last index based on whether leg index was incremented or decremented.
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
     Total seconds remaining on all legs
     */
    public var durationRemaining: CLLocationDistance {
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
    
    public var remainingWaypoints: [Waypoint] {
        return route.legs.suffix(from: legIndex).map { $0.destination }
    }
    
    public var currentLegProgress: RouteLegProgress!
    

    /**
     Intializes a new `RouteProgress`.
     
     - parameter route: The route to follow.
     - parameter legIndex: Zero-based index indicating the current leg the user is on.
     */
    public init(route: Route, legIndex: Int = 0) {
        self.route = route
        self.legIndex = legIndex
        super.init()
        currentLegProgress = RouteLegProgress(leg: currentLeg)
    }
}

/**
 `RouteLegProgress` stores the user’s progress along a route leg.
 */
@objc(MBRouteLegProgress)
open class RouteLegProgress: NSObject {
    public let leg: RouteLeg
    
    
    /**
     Index representing the current step
     */
    public var stepIndex: Int {
        didSet {
            assert(stepIndex >= 0 && stepIndex < leg.steps.endIndex)
            currentStepProgress = RouteStepProgress(step: currentStep)
        }
    }


    /**
     Total distance traveled in meters along current leg
     */
    public var distanceTraveled: CLLocationDistance {
        return leg.steps.prefix(upTo: stepIndex).map { $0.distance }.reduce(0, +) + currentStepProgress.distanceTraveled
    }
    
    
    /**
     Duration remaining in seconds on current leg
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
     Returns the `Step` before the current step.
     
     If there is no `priorStep`, nil is returned.
     */
    public var priorStep: RouteStep? {
        guard stepIndex - 1 >= 0 else {
            return nil
        }
        return leg.steps[stepIndex - 1]
    }
    
    
    /**
     Returns number representing current `Step` for the leg the user is on.
     */
    public var currentStep: RouteStep {
        return leg.steps[stepIndex]
    }


    /**
     Returns the upcoming `Step`.
     
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
     Return bool whether step provided is the current `Step` the user is on.
     */
    public func isCurrentStep(_ step: RouteStep) -> Bool {
        return step == currentStep
    }
    
    public var currentStepProgress: RouteStepProgress


    /**
     Intializes a new `RouteLegProgress`.
     
     - parameter leg: Leg on a `Route`.
     - parameter stepIndex: Current step the user is on.
     */
    public init(leg: RouteLeg, stepIndex: Int = 0) {
        self.leg = leg
        self.stepIndex = stepIndex
        currentStepProgress = RouteStepProgress(step: leg.steps[stepIndex])
    }
    
    
    /**
     Returns an array of `CLLocationCoordinate2D` of the prior, current and upcoming step geometry
     */
    public var nearbyCoordinates: [CLLocationCoordinate2D] {
        let priorCoords = priorStep?.coordinates ?? []
        let upcomingCoords = upComingStep?.coordinates ?? []
        let currentCoords = currentStep.coordinates ?? []
        let nearby = priorCoords + currentCoords + upcomingCoords
        assert(!nearby.isEmpty, "Polyline must coordinates")
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
    public var userDistanceToManeuverLocation: CLLocationDistance? = nil
    
    /**
     Total distance in meters remaining on current stpe
     */
    public var distanceRemaining: CLLocationDistance {
        return step.distance - distanceTraveled
    }

    /**
     Number between 0 and 1 representing fraction of current step traveled
     */
    public var fractionTraveled: Double {
        return distanceTraveled / step.distance
    }


    /**
     Number of seconds remaining on current step
     */
    public var durationRemaining: TimeInterval {
        return (1 - fractionTraveled) * step.expectedTravelTime
    }


    public init(step: RouteStep) {
        self.step = step
    }
}
