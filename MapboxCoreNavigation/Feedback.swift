import Foundation


private struct RawValues {
    static let accident = "accident"
    static let hazard = "hazard"
    static let roadClosed = "road_closed"
    static let unallowedTurn = "unallowed_turn"
    static let routingError = "routing_error"
    static let general = "general"
}

/**
 Feedback type is used to specify the type of feedback being recorded with `RouteController.recordFeedback()`.
 */
@objc(MBFeedbackType)
public enum FeedbackType: Int, RawRepresentable, CustomStringConvertible {
    
    public typealias RawValue = String
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
    
    public var rawValue: String {
        switch self {
        case .accident:
            return RawValues.accident
        case .hazard:
            return RawValues.hazard
        case .roadClosed:
            return RawValues.roadClosed
        case .unallowedTurn:
            return RawValues.unallowedTurn
        case .routingError:
            return RawValues.routingError
        case .general:
            return RawValues.general
        }
    }
    
    public var description: String {
        switch self {
        case .accident:
            return "Accident"
        case .hazard:
            return "Hazard"
        case .roadClosed:
            return "Road Closed"
        case .unallowedTurn:
            return "Unallowed Turn"
        case .routingError:
            return "Routing Error"
        case .general:
            return "General"
        }
    }
    
    public init?(rawValue: String) {
        switch rawValue {
            case RawValues.accident:
                self = .accident
            case RawValues.hazard:
                self = .hazard
            case RawValues.roadClosed:
                self = .roadClosed
            case RawValues.unallowedTurn:
                self = .unallowedTurn
            case RawValues.routingError:
                self = .routingError
            case RawValues.general:
                self = .general
            default:
                return nil
        }
    }
}
