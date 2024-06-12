import MapboxNavigationCore

public enum FeedbackViewControllerType {
    case activeNavigation
    case passiveNavigation
    case custom([FeedbackItem])

    var feedbackItems: [FeedbackItem] {
        switch self {
        case .activeNavigation:
            return [
                ActiveNavigationFeedbackType.badRoute,
                .illegalTurn,
                .roadClosed,
                .wrongSpeedLimit,
                .incorrectLaneGuidance,
                .other,
            ].map { $0.generateFeedbackItem() }
        case .passiveNavigation:
            return [PassiveNavigationFeedbackType.wrongSpeedLimit, .other].map { $0.generateFeedbackItem() }
        case .custom(let items):
            return items
        }
    }
}
