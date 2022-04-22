import Foundation
import CoreLocation
import MapboxDirections

/**
 `RouteLegProgress` stores the user’s progress along a route leg.
 */
open class RouteLegProgress: Codable {
    
    // MARK: Details About the Leg
    
    /**
     Returns the current `RouteLeg`.
     */
    public let leg: RouteLeg

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
        guard leg.distance > 0 else { return 1 }
        return distanceTraveled / leg.distance
    }

    public var userHasArrivedAtWaypoint = false
    
    // MARK: Details About the Leg’s Steps
    
    /**
     Index representing the current step.
     */
    public var stepIndex: Int {
        didSet {
            precondition(leg.steps.indices.contains(stepIndex), "It's not possible to set the stepIndex: \(stepIndex) when it's higher than steps count \(leg.steps.count) or not included.")
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
    
    /**
     Intializes a new `RouteLegProgress`.

     - parameter leg: Leg on a `Route`.
     - parameter stepIndex: Current step the user is on.
     */
    public init(leg: RouteLeg, stepIndex: Int = 0, spokenInstructionIndex: Int = 0) {
        precondition(leg.steps.indices.contains(stepIndex), "It's not possible to set the stepIndex: \(stepIndex) when it's higher than steps count \(leg.steps.count) or not included.")
        
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
            let closesCoordOnStepDistance = closestCoordOnStep.coordinate.distance(to: coordinate)
            let foundIndex = currentStepIndex + stepIndex

            // First time around, currentClosest will be `nil`.
            guard let currentClosestDistance = currentClosest?.distance else {
                currentClosest = (index: foundIndex, distance: closesCoordOnStepDistance)
                continue
            }

            if closesCoordOnStepDistance < currentClosestDistance {
                currentClosest = (index: foundIndex, distance: closesCoordOnStepDistance)
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
            let newSlice = slice.sliced(from: waypoint.coordinate)!
            accumulatedCoordinates += slice.coordinates.count - newSlice.coordinates.count
            slice = newSlice
            return accumulatedCoordinates <= userCoordinateIndex
        })
    }

    // MARK: - Codable implementation
    
    private enum CodingKeys: String, CodingKey {
        case leg
        case stepIndex
        case userHasArrivedAtWaypoint
        case currentStepProgress
    }
}
