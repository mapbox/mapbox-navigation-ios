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

    /// Indicates a problem with positioning the user
    case positioning(subtype: PositioningSubtype?)

    /// Description of the category for this type of feedback
    public var description: String {
        switch self {
        case .general:
            return "general"
        case .incorrectVisual(_):
            return "incorrect_visual_guidance"
        case .confusingAudio(_):
            return "incorrect_audio_guidance"
        case .routeQuality(_):
            return "routing_error"
        case .illegalRoute(_):
            return "not_allowed"
        case .roadClosure(_):
            return "road_closed"
        case .positioning(_):
            return "positioning_issue"
        }
    }

    /// Optional detailed description of the subtype of this feedback
    public var subtypeDescription: String? {
        switch self {
        case .incorrectVisual(subtype: .turnIconIncorrect):
            return "turn_icon_incorrect"
        case .incorrectVisual(subtype: .streetNameIncorrect):
            return "street_name_incorrect"
        case .incorrectVisual(subtype: .instructionUnnecessary):
            return "instruction_unnecessary"
        case .incorrectVisual(subtype: .instructionMissing):
            return "instruction_missing"
        case .incorrectVisual(subtype: .maneuverIncorrect):
            return "maneuver_incorrect"
        case .incorrectVisual(subtype: .exitInfoIncorrect):
            return "exit_info_incorrect"
        case .incorrectVisual(subtype: .laneGuidanceIncorrect):
            return "lane_guidance_incorrect"
        case .incorrectVisual(subtype: .roadKnownByDifferentName):
            return "road_known_by_different_name"
        case .confusingAudio(subtype: .guidanceTooEarly):
            return "guidance_too_early"
        case .confusingAudio(subtype: .guidanceTooLate):
            return "guidance_too_late"
        case .confusingAudio(subtype: .pronunciationIncorrect):
            return "pronunciation_incorrect"
        case .confusingAudio(subtype: .roadNameRepeated):
            return "road_name_repeated"
        case .routeQuality(subtype: .routeNonDrivable):
            return "route_not_driveable"
        case .routeQuality(subtype: .routeNotPreferred):
            return "route_not_preferred"
        case .routeQuality(subtype: .alternativeRouteNotExpected):
            return "alternative_route_not_expected"
        case .routeQuality(subtype: .routeIncludedMissingRoads):
            return "route_included_missing_roads"
        case .routeQuality(subtype: .routeHadRoadsTooNarrowToPass):
            return "route_had_roads_too_narrow_to_pass"
        case .illegalRoute(subtype: .routedDownAOneWay):
            return "routed_down_a_one_way"
        case .illegalRoute(subtype: .turnWasNotAllowed):
            return "turn_was_not_allowed"
        case .illegalRoute(subtype: .carsNotAllowedOnStreet):
            return "cars_not_allowed_on_street"
        case .illegalRoute(subtype: .turnAtIntersectionUnprotected):
            return "turn_at_intersection_was_unprotected"
        case .roadClosure(subtype: .streetPermanentlyBlockedOff):
            return "street_permanently_blocked_off"
        case .roadClosure(subtype: .roadMissingFromMap):
            return "road_is_missing_from_map"
        case .positioning(subtype: .userPosition):
            return "positioning_issue"
        default:
            return nil
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
    case other
}

/// Enum denoting the subtypes of the  `Confusing Audio` top-level category
public enum ConfusingAudioSubtype: String {
    case guidanceTooEarly
    case guidanceTooLate
    case pronunciationIncorrect
    case roadNameRepeated
    case other
}

/// Enum denoting the subtypes of the  `Route Quality` top-level category
public enum RouteQualitySubtype: String {
    case routeNonDrivable
    case routeNotPreferred
    case alternativeRouteNotExpected
    case routeIncludedMissingRoads
    case routeHadRoadsTooNarrowToPass
    case other
}

/// Enum denoting the subtypes of the  `Illegal Route` top-level category
public enum IllegalRouteSubtype: String {
    case routedDownAOneWay
    case turnWasNotAllowed
    case carsNotAllowedOnStreet
    case turnAtIntersectionUnprotected
    case other
}

/// Enum denoting the subtypes of the  `Road Closure` top-level category
public enum RoadClosureSubtype: String {
    case streetPermanentlyBlockedOff
    case roadMissingFromMap
    case other
}

public enum PositioningSubtype: String {
    case userPosition
}

/// Enum denoting the origin source of the corresponding feedback item
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
