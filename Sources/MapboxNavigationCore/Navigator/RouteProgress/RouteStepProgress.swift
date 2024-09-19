import CoreLocation
import Foundation
import MapboxDirections
import MapboxNavigationNative
import Turf

/// ``RouteStepProgress`` stores the user’s progress along a route step.
public struct RouteStepProgress: Equatable, Sendable {
    /// Intializes a new ``RouteStepProgress``.
    /// - Parameter step: Step on a ``RouteLeg``.
    public init(step: RouteStep) {
        self.step = step
    }

    func refreshingStep(with step: RouteStep) -> RouteStepProgress {
        var refreshedProgress = self

        refreshedProgress.step = step

        return refreshedProgress
    }

    // MARK: Step Stats

    mutating func update(using status: NavigationStatus) {
        guard let activeGuidanceInfo = status.activeGuidanceInfo else {
            return
        }

        distanceTraveled = activeGuidanceInfo.stepProgress.distanceTraveled
        distanceRemaining = activeGuidanceInfo.stepProgress.remainingDistance
        fractionTraveled = activeGuidanceInfo.stepProgress.fractionTraveled
        durationRemaining = activeGuidanceInfo.stepProgress.remainingDuration

        intersectionIndex = Int(status.intersectionIndex)
        visualInstructionIndex = status.bannerInstruction.map { Int($0.index) } ?? visualInstructionIndex
        // TODO: ensure NN fills these only when it is really needed (mind reroutes/alternatives switch/etc)
        spokenInstructionIndex = status.voiceInstruction.map { Int($0.index) }
        currentSpokenInstruction = status.voiceInstruction.map(SpokenInstruction.init)
    }

    /// Returns the current ``RouteStep``.
    public private(set) var step: RouteStep

    /// Returns distance user has traveled along current step.
    public private(set) var distanceTraveled: CLLocationDistance = 0

    /// Total distance in meters remaining on current step.
    public private(set) var distanceRemaining: CLLocationDistance = 0

    /// Number between 0 and 1 representing fraction of current step traveled.
    public private(set) var fractionTraveled: Double = 0

    /// Number of seconds remaining on current step.
    public private(set) var durationRemaining: TimeInterval = 0

    /// Returns remaining step shape coordinates.
    public func remainingStepCoordinates() -> [CLLocationCoordinate2D] {
        guard let shape = step.shape else {
            return []
        }

        guard let indexedStartCoordinate = shape.indexedCoordinateFromStart(distance: distanceTraveled) else {
            return []
        }

        return Array(shape.coordinates.suffix(from: indexedStartCoordinate.index))
    }

    // MARK: Intersections

    /// All intersections on the current ``RouteStep`` and also the first intersection on the upcoming ``RouteStep``.
    ///
    /// The upcoming RouteStep first Intersection is added because it is omitted from the current step.
    public var intersectionsIncludingUpcomingManeuverIntersection: [Intersection]?

    mutating func update(intersectionsIncludingUpcomingManeuverIntersection newValue: [Intersection]?) {
        intersectionsIncludingUpcomingManeuverIntersection = newValue
    }

    /// The next intersection the user will travel through.
    /// The step must contain ``intersectionsIncludingUpcomingManeuverIntersection`` otherwise this property will be
    /// `nil`.
    public var upcomingIntersection: Intersection? {
        guard let intersections = intersectionsIncludingUpcomingManeuverIntersection, intersections.count > 0,
              intersections.startIndex..<intersections.endIndex - 1 ~= intersectionIndex
        else {
            return nil
        }

        return intersections[intersections.index(after: intersectionIndex)]
    }

    /// Index representing the current intersection.
    public private(set) var intersectionIndex: Int = 0

    /// The current intersection the user will travel through.
    ///
    /// The step must contain ``intersectionsIncludingUpcomingManeuverIntersection`` otherwise this property will be
    /// `nil`.
    public var currentIntersection: Intersection? {
        guard let intersections = intersectionsIncludingUpcomingManeuverIntersection,
              intersections.indices.contains(intersectionIndex)
        else {
            return nil
        }

        return intersections[intersectionIndex]
    }

    /// The distance in meters the user is to the next intersection they will pass through.
    public var userDistanceToUpcomingIntersection: CLLocationDistance?

    // MARK: Visual and Spoken Instructions

    /// Index into `RouteStep.instructionsDisplayedAlongStep` representing the current visual instruction for the step.
    public private(set) var visualInstructionIndex: Int = 0

    /// An `Array` of remaining ``VisualInstructionBanner`` for a step.
    public var remainingVisualInstructions: [VisualInstructionBanner]? {
        guard let visualInstructions = step.instructionsDisplayedAlongStep,
              visualInstructions.indices.contains(visualInstructionIndex) else { return nil }

        return Array(visualInstructions.suffix(from: visualInstructionIndex))
    }

    /// Index into `RouteStep.instructionsSpokenAlongStep` representing the current spoken instruction.
    public private(set) var spokenInstructionIndex: Int?

    /// An `Array` of remaining ``SpokenInstruction`` for a step.
    ///
    /// Valid only when ``spokenInstructionIndex`` is known.
    public var remainingSpokenInstructions: [SpokenInstruction]? {
        guard let spokenInstructionIndex,
              let instructions = step.instructionsSpokenAlongStep,
              instructions.indices.contains(spokenInstructionIndex) else { return nil }

        return Array(instructions.suffix(from: spokenInstructionIndex))
    }

    /// Current spoken instruction for the user's progress along a step.
    public private(set) var currentSpokenInstruction: SpokenInstruction? = nil

    /// Current visual instruction for the user's progress along a step.
    public var currentVisualInstruction: VisualInstructionBanner? {
        guard let instructions = step.instructionsDisplayedAlongStep,
              instructions.indices.contains(visualInstructionIndex) else { return nil }
        return instructions[visualInstructionIndex]
    }

    public var keyPathsAffectingValueForRemainingVisualInstructions: Set<String> {
        return ["step.instructionsDisplayedAlongStep", "visualInstructionIndex"]
    }

    public var keyPathsAffectingValueForRemainingSpokenInstructions: Set<String> {
        return ["step.instructionsDisplayedAlongStep", "spokenInstructionIndex"]
    }
}

extension SpokenInstruction {
    init(_ nativeInstruction: VoiceInstruction) {
        self.init(
            distanceAlongStep: LocationDistance(nativeInstruction.remainingStepDistance), // is it the same distance?
            text: nativeInstruction.announcement,
            ssmlText: nativeInstruction.ssmlAnnouncement
        )
    }
}

extension VisualInstructionBanner {
    init(_ nativeInstruction: BannerInstruction) {
        let drivingSide: DrivingSide = if let nativeDrivingSide = nativeInstruction.primary.drivingSide,
                                          let converted = DrivingSide(rawValue: nativeDrivingSide)
        {
            converted
        } else {
            .right
        }

        self.init(
            distanceAlongStep: LocationDistance(nativeInstruction.remainingStepDistance),
            primary: .init(nativeInstruction.primary),
            secondary: nativeInstruction.secondary.map(VisualInstruction.init),
            tertiary: nativeInstruction.sub.map(VisualInstruction.init),
            quaternary: nativeInstruction.view.map(VisualInstruction.init),
            drivingSide: drivingSide
        )
    }
}

extension VisualInstruction {
    init(_ nativeInstruction: BannerSection) {
        let maneuverType = nativeInstruction.type.map(ManeuverType.init(rawValue:)) ?? nil
        let maneuverDirection = nativeInstruction.modifier.map(ManeuverDirection.init(rawValue:)) ?? nil
        let components = nativeInstruction.components?.map(VisualInstruction.Component.init) ?? []

        self.init(
            text: nativeInstruction.text,
            maneuverType: maneuverType,
            maneuverDirection: maneuverDirection,
            components: components,
            degrees: nativeInstruction.degrees?.doubleValue
        )
    }
}

extension VisualInstruction.Component {
    init(_ nativeComponent: BannerComponent) {
        let textRepresentation = TextRepresentation(
            text: nativeComponent.text,
            abbreviation: nativeComponent.abbr,
            abbreviationPriority: nativeComponent.abbrPriority?.intValue
        )
        // TODO: get rid of constants
        switch nativeComponent.type {
        case "delimeter":
            self = .delimiter(text: textRepresentation)
            return
        case "text":
            self = .text(text: textRepresentation)
            return
        case "image":
            guard let nativeShield = nativeComponent.shield,
                  let baseURL = URL(string: nativeShield.baseUrl),
                  let imageBaseURL = nativeComponent.imageBaseUrl
            else {
                break
            }
            let shield = ShieldRepresentation(
                baseURL: baseURL,
                name: nativeShield.name,
                textColor: nativeShield.textColor,
                text: nativeShield.displayRef
            )
            self = .image(
                image: ImageRepresentation(
                    imageBaseURL: URL(string: imageBaseURL),
                    shield: shield
                ),
                alternativeText: textRepresentation
            )
            return
        case "guidance-view":
            guard let imageURL = nativeComponent.imageURL else {
                break
            }
            self = .guidanceView(
                image: GuidanceViewImageRepresentation(imageURL: URL(string: imageURL)),
                alternativeText: textRepresentation
            )
            return
        case "exit":
            self = .exit(text: textRepresentation)
            return
        case "exit-number":
            self = .exitCode(text: textRepresentation)
            return
        case "lane":
            guard let directions = nativeComponent.directions,
                  let indications = LaneIndication(descriptions: directions)
            else {
                break
            }
            let activeDirection = nativeComponent.activeDirection
            let preferredDirection = activeDirection.flatMap { ManeuverDirection(rawValue: $0) }
            self = .lane(
                indications: indications,
                isUsable: nativeComponent.active?.boolValue ?? false,
                preferredDirection: preferredDirection
            )
            return
        default:
            break
        }
        self = .text(text: textRepresentation)
    }
}
