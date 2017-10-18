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
     Identifies the feedback as a turn that isn't allowed. For example, if a user is instructed to make a left turn, but the turn isn't allowed.
     */
    case unallowedTurn
    
    /**
     Identifies the feedback as the location of a poor instruction or route choice. This could be used to indicate an ambiguous or poorly-timed turn announcement, or a set of confusing turns.
     */
    case routingError
    
    /**
     Identifies the feedback as the location of an instruction with bad timing. For example after the maneuver should have occured.
     */
    case instructionTiming
    
    /**
     Identifies the feedback as the location of a confusing instruction.
     */
    case confusingInstruction
    
    /**
     Identifies the feedback as a place where the GPS quality was particularly poor.
     */
    case inaccurateGPS
    
    /**
     Identifies the feedback where the route was inefficient.
     */
    case badRoute
    
    /**
     Identifies the feedback as a place where traffic should have been reported.
     */
    case reportTraffic
    
    /**
     Identifies the feedback as a place with general instruction issue.
     */
    case instructionIssue
    
    /**
     Identifies the feedback as a place with heavy traffic could have been avoided by using a smarter route.
     */
    case heavyTraffic
    
    public var description: String {
        switch self {
        case .accident:
            return "accident"
        case .hazard:
            return "hazard"
        case .roadClosed:
            return "road_closed"
        case .unallowedTurn:
            return "unallowed_turn"
        case .routingError:
            return "routing_error"
        case .general:
            return "general"
        case .instructionTiming:
            return "instruction_timing"
        case .confusingInstruction:
            return "confusing_instruction"
        case .inaccurateGPS:
            return "inaccurate_gps"
        case .badRoute:
            return "bad_route"
        case .reportTraffic:
            return "report_traffic"
        case .instructionIssue:
            return "instruction_issue"
        case .heavyTraffic:
            return "heavy_traffic"
        }
    }
}
