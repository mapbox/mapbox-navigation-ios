import Foundation

/**
 Feedback type is used to specify the type of feedback being recorded with `RouteController.recordFeedback()`.
 */
@objc(MBFeedbackType)
public enum FeedbackType: Int, CustomStringConvertible {
    /**
     Indicates general feedback. You should provide a `description` string to `RouteController.recordFeedback()` to elaborate on the feedback if possible.
     */
    case general
    
    /**
     Identifies the feedback as the location of an accident or crash
     */
    case accident
    
    /**
     Identifies the feedback as the location of a road hazard such as debris, stopped vehicles, etc.
     */
    case hazard
    
    /**
     Identifies the feedback as the location of a closed road that should not allow vehicles
     */
    case roadClosed
    
    /**
     Identifies the feedback as a maneuver that isn't allowed. For example, if a user is instructed to make a left turn, but the turn isn't allowed.
     */
    case notAllowed
    
    /**
     Identifies the feedback as the location of a road that should exist along the route.
     */
    case missingRoad
    
    /**
     Identifies the feedback as a maneuver with missing exit information such as an exit number or destination sign.
     */
    case missingExit
    
    /**
     Identifies the feedback as the location of a poor instruction or route choice. This could be used to indicate an ambiguous or poorly-timed turn announcement, or a set of confusing turns.
     */
    case routingError
    
    /**
     Identifies the feedback as the location of a confusing instruction.
     */
    case confusingInstruction
    
    /**
     Identifies the feedback as a place where traffic should have been reported.
     */
    case reportTraffic
    
    /**
     Identifies the feedback as a general map issue.
     */
    case mapIssue
    
    public var description: String {
        switch self {
        case .general:
            return "general"
        case .accident:
            return "accident"
        case .hazard:
            return "hazard"
        case .roadClosed:
            return "road_closed"
        case .notAllowed:
            return "not_allowed"
        case .missingRoad:
            return "missing_road"
        case .missingExit:
            return "missing_exit"
        case .routingError:
            return "routing_error"
        case .confusingInstruction:
            return "confusing_instruction"
        case .reportTraffic:
            return "report_traffic"
        case .mapIssue:
            return "other_map_issue"
        }
    }
}

@objc(MBFeedbackSource)
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
