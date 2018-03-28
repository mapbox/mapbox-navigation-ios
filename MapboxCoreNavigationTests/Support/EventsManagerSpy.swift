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
        print("enqueueEvent...")
        let event: MockTelemetryEvent = MockTelemetryEvent(name: name, attributes: attributes)
        enqueuedEvents.append(event)
    }

    override func flush() {
        print("flush")
        enqueuedEvents.forEach { (event: MockTelemetryEvent) in
            flushedEvents.append(event)
        }
    }

    public func hasFlushedEvent(with name: String) -> Bool {
        print("hasFlushedEvent(with:)")
        for event in flushedEvents {
//            print("event: \(event.name)")
            if event.name == name {
                return true
            }
        }
        return false
    }

    public func hasEnqueuedEvent(with name: String) -> Bool {
        print("hasEnqueuedEvent(with:)")
        for event in enqueuedEvents {
//            print("event: \(event.name)")
            if event.name == name {
                return true
            }
        }
        return false
    }
}
