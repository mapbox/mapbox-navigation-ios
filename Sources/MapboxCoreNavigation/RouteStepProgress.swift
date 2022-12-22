import Foundation
import CoreLocation
import MapboxDirections
import Polyline

/**
 `RouteStepProgress` stores the user’s progress along a route step.
 */
open class RouteStepProgress: Codable {
    
    /**
     Intializes a new `RouteStepProgress`.

     - parameter step: Step on a `RouteLeg`.
     */
    public init(step: RouteStep, spokenInstructionIndex: Int = 0, intersectionIndex: Int = 0) {
        self.step = step
        self.userDistanceToManeuverLocation = step.distance
        self.spokenInstructionIndex = spokenInstructionIndex
        self.intersectionIndex = intersectionIndex
    }
    
    // MARK: Step Stats
    
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

    /// Returns remaining step shape coordinates.
    public func remainingStepCoordinates() -> [LocationCoordinate2D] {
        guard let shape = step.shape else {
            return []
        }

        let startCoordinate = shape.coordinateFromStart(distance: distanceTraveled)
        return shape.sliced(from: startCoordinate)?.coordinates ?? []
    }

    // MARK: Intersections
    
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
        guard let intersections = intersectionsIncludingUpcomingManeuverIntersection, intersections.count > 0,
              intersections.startIndex..<intersections.endIndex-1 ~= intersectionIndex else {
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
        guard let intersections = intersectionsIncludingUpcomingManeuverIntersection,
              intersections.indices.contains(intersectionIndex) else {
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

    // MARK: Visual and Spoken Instructions
    
    /**
     Index into `step.instructionsDisplayedAlongStep` representing the current visual instruction for the step.
     */
    public var visualInstructionIndex: Int = 0

    /**
     An `Array` of remaining `VisualInstruction` for a step.
     */
    public var remainingVisualInstructions: [VisualInstructionBanner]? {
        guard let visualInstructions = step.instructionsDisplayedAlongStep,
              visualInstructions.indices.contains(visualInstructionIndex) else { return nil }

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
        guard let instructions = step.instructionsSpokenAlongStep,
              instructions.indices.contains(spokenInstructionIndex) else { return nil }

        return Array(instructions.suffix(from: spokenInstructionIndex))
    }

    /**
     Current spoken instruction for the user's progress along a step.
     */
    public var currentSpokenInstruction: SpokenInstruction? {
        guard let instructionsSpokenAlongStep = step.instructionsSpokenAlongStep,
              instructionsSpokenAlongStep.indices.contains(spokenInstructionIndex) else { return nil }

        return instructionsSpokenAlongStep[spokenInstructionIndex]
    }

    /**
     Current visual instruction for the user's progress along a step.
     */
    public var currentVisualInstruction: VisualInstructionBanner? {
        guard let instructionsDisplayedAlongStep = step.instructionsDisplayedAlongStep,
              instructionsDisplayedAlongStep.indices.contains(visualInstructionIndex) else { return nil }

        return instructionsDisplayedAlongStep[visualInstructionIndex]
    }
    
    public var keyPathsAffectingValueForRemainingVisualInstructions: Set<String> {
        return ["step.instructionsDisplayedAlongStep", "visualInstructionIndex"]
    }
    
    public var keyPathsAffectingValueForRemainingSpokenInstructions: Set<String> {
        return ["step.instructionsDisplayedAlongStep", "spokenInstructionIndex"]
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case step
        case userDistanceToManeuverLocation
        case intersectionsIncludingUpcomingManeuverIntersection
        case intersectionIndex
        case intersectionDistances
        case userDistanceToUpcomingIntersection
        case visualInstructionIndex
        case spokenInstructionIndex
    }
}
