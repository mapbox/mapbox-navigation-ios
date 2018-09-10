import Foundation
import MapboxMobileEvents

typealias MockTelemetryEvent = (name: String, attributes: [String: Any])

@objc(MBEventsManagerSpy)
class MMEEventsManagerSpy: MMEEventsManager {

    private var enqueuedEvents = [MockTelemetryEvent]()
    private var flushedEvents = [MockTelemetryEvent]()

    public func reset() {
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

    override func sendTurnstileEvent() {
        flushedEvents.append((name: "???", attributes: ["event" : MMEEventTypeAppUserTurnstile, "eventsManager" : String(describing: self)]))
    }

    override func flush() {
        enqueuedEvents.forEach { (event: MockTelemetryEvent) in
            flushedEvents.append(event)
        }
    }

    public func hasFlushedEvent(with name: String) -> Bool {
        return flushedEvents.contains(where: { (event) -> Bool in
            return event.attributes["event"] as! String == name
        })
    }

    public func hasEnqueuedEvent(with name: String) -> Bool {
        return enqueuedEvents.contains(where: { (event) -> Bool in
            return event.attributes["event"] as! String == name
        })
    }

    public func enqueuedEventCount(with name: String) -> Int {
        return enqueuedEvents.filter { (event) in
            return event.attributes["event"] as! String == name
        }.count
    }

    public func flushedEventCount(with name: String) -> Int {
        return flushedEvents.filter { (event) in
            return event.attributes["event"] as! String == name
        }.count
    }
}

import MapboxCoreNavigation

class TestNavigationEventsManager: EventsManager {
    init() {
        super.init(accessToken: "not a real token")
        self.manager = MMEEventsManagerSpy()
    }
}
