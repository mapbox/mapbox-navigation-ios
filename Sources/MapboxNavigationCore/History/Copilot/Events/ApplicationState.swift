import Foundation

extension NavigationHistoryEvents {
    enum ApplicationState {
        case goingToBackground
        case goingToForeground
    }
}

extension NavigationHistoryEvents.ApplicationState: NavigationHistoryEvents.Event {
    var eventType: String {
        switch self {
        case .goingToBackground:
            return "going_to_background"
        case .goingToForeground:
            return "going_to_foreground"
        }
    }

    var payload: String? { nil }
}
