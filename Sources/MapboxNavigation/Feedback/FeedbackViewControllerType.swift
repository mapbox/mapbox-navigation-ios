import MapboxCoreNavigation

public enum FeedbackViewControllerType {
    case activeNavigation
    case passiveNavigation
    case custom([FeedbackItem])
    
    var feedbackItems: [FeedbackItem] {
        switch self {
        case .activeNavigation:
            return [ActiveNavigationFeedbackType.incorrectVisual(subtype: nil),
                    ActiveNavigationFeedbackType.confusingAudio(subtype: nil),
                    ActiveNavigationFeedbackType.illegalRoute(subtype: nil),
                    ActiveNavigationFeedbackType.roadClosure(subtype: nil),
                    ActiveNavigationFeedbackType.routeQuality(subtype: nil),
                    ActiveNavigationFeedbackType.positioning(subtype: nil)].map { $0.generateFeedbackItem() }
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
