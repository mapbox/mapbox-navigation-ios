import Foundation


@objc(MBFeedbackType)
public enum FeedbackType: Int, CustomStringConvertible {
    case accident
    case hazard
    case roadClosed
    case unallowedTurn
    case routingError
    case general
    
    
    public init?(description: String) {
        let level: FeedbackType
        switch description {
        case "accident":
            level = .accident
        case "hazard":
            level = .hazard
        case "road_closed":
            level = .roadClosed
        case "unallowed_turn":
            level = .unallowedTurn
        case "routing_error":
            level = .routingError
        case "general":
            level = .general
        default:
            return nil
        }
        self.init(rawValue: level.rawValue)
    }
    
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
