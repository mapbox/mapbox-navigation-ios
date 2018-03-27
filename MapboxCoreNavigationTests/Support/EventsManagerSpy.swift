import Foundation
import MapboxMobileEvents

typealias MockTelemetryEvent = (name: String, attributes: [String: Any])

class EventsManagerSpy: MMEEventsManager {

    private var enqueuedEvents = [MockTelemetryEvent]()
    private var flushedEvents = [MockTelemetryEvent]()

    func reset() {
        enqueuedEvents.removeAll()
        flushedEvents.removeAll()
    }

    override func enqueueEvent(withName name: String) {
        self.enqueueEvent(withName: name, attributes: [:])
    }

    override func enqueueEvent(withName name: String, attributes: [String: Any] = [:]) {
        let event: MockTelemetryEvent = MockTelemetryEvent(name: name, attributes: attributes)
        enqueuedEvents.append(event)
    }

    override func flush() {
        enqueuedEvents.forEach { (event: MockTelemetryEvent) in
            flushedEvents.append(event)
        }
    }

    public func hasFlushedEvent(with name: String) -> Bool {
        for event in flushedEvents {
            if event.name == name {
                return true
            }
        }
        return false
    }

    public func hasEnqueuedEvent(with name: String) -> Bool {
        for event in enqueuedEvents {
            if event.name == name {
                return true
            }
        }
        return false
    }
}
