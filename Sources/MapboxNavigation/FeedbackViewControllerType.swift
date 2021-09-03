import MapboxCoreNavigation

public enum FeedbackViewControllerType {
    case activeNavigation
    case passiveNavigation
    case custom([FeedbackItem])
    
    var feedbackItems: [FeedbackItem] {
        switch self {
        case .activeNavigation:
            return [FeedbackType.incorrectVisual(subtype: nil),
                    FeedbackType.confusingAudio(subtype: nil),
                    FeedbackType.illegalRoute(subtype: nil),
                    FeedbackType.roadClosure(subtype: nil),
                    FeedbackType.routeQuality(subtype: nil),
                    FeedbackType.positioning(subtype: nil)].map { $0.generateFeedbackItem() }
        case .passiveNavigation:
            return [PassiveNavigationFeedbackType.incorrectVisual(subtype: nil),
                    PassiveNavigationFeedbackType.roadIssue(subtype: nil),
                    PassiveNavigationFeedbackType.wrongTraffic(subtype: nil),
                    PassiveNavigationFeedbackType.badGPS].map { $0.generateFeedbackItem() }
        case .custom(let items):
            return items
        }
    }
}
