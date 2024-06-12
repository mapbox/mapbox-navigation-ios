import CoreLocation
import Foundation
import MapboxNavigationNative

struct EventStep: Equatable, Codable {
    let distance: Double
    let distanceRemaining: Double
    let duration: Double
    let durationRemaining: Double
    let upcomingName: String
    let upcomingType: String
    let upcomingModifier: String
    let upcomingInstruction: String
    let previousName: String
    let previousType: String
    let previousModifier: String
    let previousInstruction: String

    /// Initializes an event location consistent with the given location object.
    init(_ step: Step) {
        self.distance = step.distance
        self.distanceRemaining = step.distanceRemaining
        self.duration = step.duration
        self.durationRemaining = step.durationRemaining
        self.upcomingName = step.upcomingName
        self.upcomingType = step.upcomingType
        self.upcomingModifier = step.upcomingModifier
        self.upcomingInstruction = step.upcomingInstruction
        self.previousName = step.previousName
        self.previousType = step.previousType
        self.previousModifier = step.previousModifier
        self.previousInstruction = step.previousInstruction
    }
}

extension Step {
    convenience init?(_ step: EventStep?) {
        guard let step else { return nil }

        self.init(
            distance: step.distance,
            distanceRemaining: step.distanceRemaining,
            duration: step.duration,
            durationRemaining: step.durationRemaining,
            upcomingName: step.upcomingName,
            upcomingType: step.upcomingType,
            upcomingModifier: step.upcomingModifier,
            upcomingInstruction: step.upcomingInstruction,
            previousName: step.previousName,
            previousType: step.previousType,
            previousModifier: step.previousModifier,
            previousInstruction: step.previousInstruction
        )
    }
}
