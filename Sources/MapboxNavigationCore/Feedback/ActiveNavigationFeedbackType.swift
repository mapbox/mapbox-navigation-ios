import Foundation

/// Feedback type is used to specify the type of feedback being recorded with
/// ``NavigationEventsManager/sendActiveNavigationFeedback(_:type:description:)``.
public enum ActiveNavigationFeedbackType: FeedbackType {
    case closure
    case poorRoute
    case wrongSpeedLimit

    case badRoute
    case illegalTurn
    case roadClosed
    case incorrectLaneGuidance
    case other
    case arrival(rating: Int)

    /// Description of the category for this type of feedback
    public var typeKey: String {
        switch self {
        case .closure:
            return "ag_missing_closure"
        case .poorRoute:
            return "ag_poor_route"
        case .wrongSpeedLimit:
            return "ag_wrong_speed_limit"
        case .badRoute:
            return "routing_error"
        case .illegalTurn:
            return "turn_was_not_allowed"
        case .roadClosed:
            return "road_closed"
        case .incorrectLaneGuidance:
            return "lane_guidance_incorrect"
        case .other:
            return "other_navigation"
        case .arrival:
            return "arrival"
        }
    }

    /// Optional detailed description of the subtype of this feedback
    public var subtypeKey: String? {
        if case .arrival(let rating) = self {
            return String(rating)
        }
        return nil
    }
}

/// Enum denoting the origin source of the corresponding feedback item
public enum FeedbackSource: Int, CustomStringConvertible, Sendable {
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
