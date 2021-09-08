import Foundation

/**
 Feedback type is used to specify the type of feedback being recorded with `NavigationEventsManager.sendActiveNavigationFeedback(_:type:description:)`.
 */
public enum ActiveNavigationFeedbackType: FeedbackType {

    /// Indicates an incorrect visual instruction or other user interface issue.
    case looksIncorrect(subtype: LooksIncorrectSubtype?)

    /// Indicates confusing voice instruction.
    case confusingAudio(subtype: ConfusingAudioSubtype?)

    /// Indicates an issue with route quality.
    case routeQuality(subtype: RouteQualitySubtype?)

    /// Indicates that an illegal route was recommended.
    case illegalRoute(subtype: IllegalRouteSubtype?)

    /// Indicates a road closure was observed.
    case roadClosure(subtype: RoadClosureSubtype?)

    /// Indicates a problem with positioning the user
    case positioning
    
    /// Indicates a custom feedback type and subtype.
    case custom(typeKey: String, subtypeKey: String?)
    
    /// Indicates other feedback. You should provide a `description` string to `NavigationEventsManager.sendActiveNavigationFeedback(_:type:description:)`
    /// to elaborate on the feedback if possible.
    case other

    /// Description of the category for this type of feedback
    public var typeKey: String {
        switch self {
        case .looksIncorrect:
            return "incorrect_visual_guidance"
        case .confusingAudio:
            return "incorrect_audio_guidance"
        case .routeQuality:
            return "routing_error"
        case .illegalRoute:
            return "route_not_allowed"
        case .roadClosure:
            return "road_closed"
        case .positioning:
            return "positioning_issue"
        case .custom(let typeKey, _):
            return typeKey
        case .other:
            return "other_issue"
        }
    }

    /// Optional detailed description of the subtype of this feedback
    public var subtypeKey: String? {
        switch self {
        case .looksIncorrect(subtype: .turnIconIncorrect):
            return "turn_icon_incorrect"
        case .looksIncorrect(subtype: .streetNameIncorrect):
            return "street_name_incorrect"
        case .looksIncorrect(subtype: .instructionUnnecessary):
            return "instruction_unnecessary"
        case .looksIncorrect(subtype: .instructionMissing):
            return "instruction_missing"
        case .looksIncorrect(subtype: .maneuverIncorrect):
            return "maneuver_incorrect"
        case .looksIncorrect(subtype: .exitInfoIncorrect):
            return "exit_info_incorrect"
        case .looksIncorrect(subtype: .laneGuidanceIncorrect):
            return "lane_guidance_incorrect"
        case .looksIncorrect(subtype: .incorrectSpeedLimit):
            return "incorrect_speed_limit"
        case .confusingAudio(subtype: .guidanceTooEarly):
            return "guidance_too_early"
        case .confusingAudio(subtype: .guidanceTooLate):
            return "guidance_too_late"
        case .confusingAudio(subtype: .pronunciationIncorrect):
            return "pronunciation_incorrect"
        case .confusingAudio(subtype: .roadNameRepeated):
            return "road_name_repeated"
        case .confusingAudio(subtype: .instructionMissing):
            return "instruction_missing"
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
        case .roadClosure(subtype: .streetPermanentlyBlockedOff):
            return "street_permanently_blocked_off"
        case .other:
            return "other_issue"
        case .custom(_, let subtypeKey):
            return subtypeKey
        case .positioning,
                .looksIncorrect(subtype: nil),
                .confusingAudio(subtype: nil),
                .routeQuality(subtype: nil),
                .illegalRoute(subtype: nil),
                .roadClosure(subtype: nil):
            return nil
        }
    }
}

/// Enum denoting the subtypes of the  `Looks Incorrect` top-level category
public enum LooksIncorrectSubtype: String, CaseIterable {
    case turnIconIncorrect
    case streetNameIncorrect
    case instructionUnnecessary
    case instructionMissing
    case maneuverIncorrect
    case exitInfoIncorrect
    case laneGuidanceIncorrect
    case incorrectSpeedLimit
}

/// Enum denoting the subtypes of the  `Confusing Audio` top-level category
public enum ConfusingAudioSubtype: String, CaseIterable {
    case guidanceTooEarly
    case guidanceTooLate
    case pronunciationIncorrect
    case roadNameRepeated
    case instructionMissing
}

/// Enum denoting the subtypes of the  `Route Quality` top-level category
public enum RouteQualitySubtype: String, CaseIterable {
    case routeNonDrivable
    case routeNotPreferred
    case alternativeRouteNotExpected
    case routeIncludedMissingRoads
    case routeHadRoadsTooNarrowToPass
}

/// Enum denoting the subtypes of the  `Illegal Route` top-level category
public enum IllegalRouteSubtype: String, CaseIterable {
    case routedDownAOneWay
    case turnWasNotAllowed
    case carsNotAllowedOnStreet
}

/// Enum denoting the subtypes of the  `Road Closure` top-level category
public enum RoadClosureSubtype: String, CaseIterable {
    case streetPermanentlyBlockedOff
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
