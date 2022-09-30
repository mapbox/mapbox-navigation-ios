import Foundation
@testable import MapboxCoreNavigation

class EventsAPIMock: EventsAPI {
    private typealias MockEvent = [String: Any]

    private var queuedEvents = [MockEvent]()
    private var immediateEvents = [MockEvent]()

    func sendTurnstileEvent(sdkIdentifier: String, sdkVersion: String) {
        immediateEvents.append([EventKey.event.rawValue: EventType.turnstile.rawValue])
    }

    func sendQueuedEvent(with attributes: [String: Any]) {
        queuedEvents.append(attributes)
    }

    func sendImmediateEvent(with attributes: [String: Any]) {
        immediateEvents.append(attributes)
    }

    func reset() {
        queuedEvents.removeAll()
        immediateEvents.removeAll()
    }

    func hasQueuedEvent(with name: String) -> Bool {
        return hasEvent(in: queuedEvents, key: .event, value: name)
    }

    func hasImmediateEvent(with name: String) -> Bool {
        return hasEvent(in: immediateEvents, key: .event, value: name)
    }

    func immediateEventCount(with name: String) -> Int {
        return immediateEvents.filter { (event) in
            return event[EventKey.event.rawValue] as? String == name
        }.count
    }

    private func hasEvent<ValueType>(in array: [MockEvent], key: EventKey, value: ValueType) -> Bool where ValueType: Comparable {
        return array.contains { (event) -> Bool in
            guard
                let eventValue = event[key.rawValue] as? ValueType,
                eventValue == value
            else { return false }
            return true
        }
    }
}
