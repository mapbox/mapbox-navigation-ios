import Foundation

public protocol NavigationHistoryEvent {
    associatedtype Payload: Encodable

    var eventType: String { get }
    var payload: Payload { get }
}

public enum NavigationHistoryEvents {
    typealias Event = NavigationHistoryEvent
}
