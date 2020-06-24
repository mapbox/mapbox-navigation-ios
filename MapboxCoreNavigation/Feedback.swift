import Foundation

/**
 Feedback type is used to specify the type of feedback being recorded with `NavigationEventsManager.recordFeedback(type:description:)`.
 */
public enum FeedbackType: Int, CustomStringConvertible {

    /// Indicates general feedback. You should provide a `description` string to `NavigationEventsManager.recordFeedback(type:description:)`
    /// to elaborate on the feedback if possible.
    case general

    /// Indicates an incorrect visual artifact.
    case incorrectVisual

    /// Indicates confusing voice instruction.
    case confusingAudio

    /// Indicates an issue with route quality.
    case routeQuality

    /// Indicates that an illegal route was recommended.
    case illegalRoute

    /// Indicates a road closure was observed.
    case roadClosure

    
    public var description: String {
        switch self {
        case .general:
            return "general"
        case .incorrectVisual:
            return "incorrect_visual"
        case .confusingAudio:
            return "confusing_audio"
        case .routeQuality:
            return "route_quality"
        case .illegalRoute:
            return "illegal_route"
        case .roadClosure:
            return "road_closure"
        }
    }

    /// Returns a corresponding list of `FeedbackSubType`s for a given `FeedbackType`
    public var subtypes: [FeedbackSubType] {
        switch self {
        case .general:
            return []
        case .incorrectVisual:
            return [.turnIconIncorrect,
                    .streetNameIncorrect,
                    .instructionUnnecessary,
                    .instructionMissing,
                    .maneuverIncorrect,
                    .exitInfoIncorrect,
                    .laneGuidanceIncorrect,
                    .roadKnownByDifferentName]
        case .confusingAudio:
            return [.guidanceTooEarly,
                    .guidanceTooLate,
                    .pronunciationIncorrect,
                    .roadNameRepeated]
        case .routeQuality:
            return [.routeNonDrivable,
                    .routeNotPreferred,
                    .alternativeRouteNotExpected,
                    .routeIncludedMissingRoads,
                    .routeHadRoadsTooNarrowToPass]
        case .illegalRoute:
            return [.routedDownAOneWay,
                    .turnWasNotAllowed,
                    .carsNotAllowedOnStreet,
                    .turnAtIntersectionUnprotected]
        case .roadClosure:
            return [.streetPermanentlyBlockedOff,
                    .roadMissingFromMap]

        }
    }



}

/// Enum used to define the many `FeedbackSubType`s that may be nested under a given `FeedbackType`
public enum FeedbackSubType: String {
    /// Incorrect Visual Subtypes
    case turnIconIncorrect
    case streetNameIncorrect
    case instructionUnnecessary
    case instructionMissing
    case maneuverIncorrect
    case exitInfoIncorrect
    case laneGuidanceIncorrect
    case roadKnownByDifferentName

    /// Confusing Audio subtypes
    case guidanceTooEarly
    case guidanceTooLate
    case pronunciationIncorrect
    case roadNameRepeated

    /// Route Quality subtypes
    case routeNonDrivable
    case routeNotPreferred
    case alternativeRouteNotExpected
    case routeIncludedMissingRoads
    case routeHadRoadsTooNarrowToPass

    /// Illegal Route subtypes
    case routedDownAOneWay
    case turnWasNotAllowed
    case carsNotAllowedOnStreet
    case turnAtIntersectionUnprotected

    /// Road closure subtypes
    case streetPermanentlyBlockedOff
    case roadMissingFromMap
}

public enum FeedbackSource: Int, CustomStringConvertible {
    case user
    case reroute
    case unknown
    
    public var description: String {
        switch self {
        case .user:
            return "user"
        case .reroute:
            return "reroute"
        case .unknown:
            return "unknown"
        }
    }
}
