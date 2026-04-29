import MapboxNavigationCore

public enum FeedbackViewControllerType {
    case activeNavigation
    case passiveNavigation
    case custom([FeedbackItem])

    var feedbackItems: [FeedbackItem] {
        switch self {
        case .activeNavigation:
            return [
                ActiveNavigationFeedbackType.falsePositiveTraffic,
                ActiveNavigationFeedbackType.falseNegativeTraffic,
                ActiveNavigationFeedbackType.missingConstruction,
                ActiveNavigationFeedbackType.closure,
                ActiveNavigationFeedbackType.wrongSpeedLimit,
                ActiveNavigationFeedbackType.missingSpeedLimit,
            ].map { $0.generateFeedbackItem() }
        case .passiveNavigation:
            return [
                PassiveNavigationFeedbackType.poorGPS,
                PassiveNavigationFeedbackType.incorrectMapData,
                PassiveNavigationFeedbackType.accident,
                PassiveNavigationFeedbackType.camera,
                PassiveNavigationFeedbackType.traffic,
                PassiveNavigationFeedbackType.wrongSpeedLimit,
            ].map { $0.generateFeedbackItem() }
        case .custom(let items):
            return items
        }
    }
}
