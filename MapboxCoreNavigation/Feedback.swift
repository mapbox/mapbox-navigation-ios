import Foundation

/**
 Feedback type is used to specify the type of feedback being recorded with `NavigationEventsManager.recordFeedback(type:description:)`.
 */
public enum FeedbackType: CustomStringConvertible {

    /// Indicates general feedback. You should provide a `description` string to `NavigationEventsManager.recordFeedback(type:description:)`
    /// to elaborate on the feedback if possible.
    case general

    /// Indicates an incorrect visual.
    case incorrectVisual(subtype: IncorrectVisualSubtype?)

    /// Indicates confusing voice instruction.
    case confusingAudio(subtype: ConfusingAudioSubtype?)

    /// Indicates an issue with route quality.
    case routeQuality(subtype: RouteQualitySubtype?)

    /// Indicates that an illegal route was recommended.
    case illegalRoute(subtype: IllegalRouteSubtype?)

    /// Indicates a road closure was observed.
    case roadClosure(subtype: RoadClosureSubtype?)
    
    public var description: String {
        switch self {
        case .general:
            return "general"
        case .incorrectVisual(_):
            return "incorrect_visual"
        case .confusingAudio(_):
            return "confusing_audio"
        case .routeQuality(_):
            return "route_quality"
        case .illegalRoute(_):
            return "illegal_route"
        case .roadClosure(_):
            return "road_closure"
        }
    }
}

/// Enum denoting the subtypes of the  `Incorrect Visual` top-level category
public enum IncorrectVisualSubtype: String {
    case turnIconIncorrect
    case streetNameIncorrect
    case instructionUnnecessary
    case instructionMissing
    case maneuverIncorrect
    case exitInfoIncorrect
    case laneGuidanceIncorrect
    case roadKnownByDifferentName
}

/// Enum denoting the subtypes of the  `Confusing Audio` top-level category
public enum ConfusingAudioSubtype: String {
    case guidanceTooEarly
    case guidanceTooLate
    case pronunciationIncorrect
    case roadNameRepeated
}

/// Enum denoting the subtypes of the  `Route Quality` top-level category
public enum RouteQualitySubtype: String {
    case routeNonDrivable
    case routeNotPreferred
    case alternativeRouteNotExpected
    case routeIncludedMissingRoads
    case routeHadRoadsTooNarrowToPass
}

/// Enum denoting the subtypes of the  `Illegal Route` top-level category
public enum IllegalRouteSubtype: String {
    case routedDownAOneWay
    case turnWasNotAllowed
    case carsNotAllowedOnStreet
    case turnAtIntersectionUnprotected
}

/// Enum denoting the subtypes of the  `Road Closure` top-level category
public enum RoadClosureSubtype: String {
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
