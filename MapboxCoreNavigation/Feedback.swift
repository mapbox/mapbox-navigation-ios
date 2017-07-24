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
        }
    }
}
