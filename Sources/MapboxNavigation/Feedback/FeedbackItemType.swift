import MapboxCoreNavigation

public enum FeedbackItemType: Equatable {
    case activeNavigation(ActiveNavigationFeedbackType)
    case passiveNavigation(PassiveNavigationFeedbackType)
    
    public static func == (lhs: FeedbackItemType, rhs: FeedbackItemType) -> Bool {
        switch (lhs, rhs) {
        case (.activeNavigation(let leftType), .activeNavigation(let rightType)):
            return leftType.title == rightType.title
        case (.passiveNavigation(let leftType), .passiveNavigation(let rightType)):
            return leftType.title == rightType.title
        default:
            return false
        }
    }
    
    var title: String {
        switch self {
        case .activeNavigation(let type):
            return type.title
        case .passiveNavigation(let type):
            return type.title
        }
    }
}
