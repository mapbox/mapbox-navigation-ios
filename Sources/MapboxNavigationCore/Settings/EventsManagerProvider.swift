import Foundation

struct EventsManagerProvider: Equatable {
    static func == (lhs: EventsManagerProvider, rhs: EventsManagerProvider) -> Bool {
        return lhs.object === rhs.object
    }

    private var object: NavigationEventsManager
    func callAsFunction() -> NavigationEventsManager {
        return object
    }

    init(_ object: NavigationEventsManager) {
        self.object = object
    }
}
