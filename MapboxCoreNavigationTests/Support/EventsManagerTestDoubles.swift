import Foundation
import MapboxMobileEvents
@testable import MapboxCoreNavigation
import MapboxDirections

class NavigationEventsManagerSpy: NavigationEventsManager {

    private var mobileEventsManagerSpy: MMEEventsManagerSpy!

    required init(dataSource source: EventsManagerDataSource, accessToken possibleToken: String?, mobileEventsManager: MMEEventsManager) {
        mobileEventsManagerSpy = MMEEventsManagerSpy()
        super.init(dataSource: source, accessToken: possibleToken, mobileEventsManager: mobileEventsManagerSpy)
    }

    func reset() {
        mobileEventsManagerSpy.reset()
    }

    func hasFlushedEvent(with eventName: String) -> Bool {
        return mobileEventsManagerSpy.hasFlushedEvent(with: eventName)
    }

    func hasEnqueuedEvent(with eventName: String) -> Bool {
        return mobileEventsManagerSpy.hasEnqueuedEvent(with: eventName)
    }

    func enqueuedEventCount(with eventName: String) -> Int {
        return mobileEventsManagerSpy.enqueuedEventCount(with: eventName)
    }

    func flushedEventCount(with eventName: String) -> Int {
        return mobileEventsManagerSpy.flushedEventCount(with: eventName)
    }
}

typealias FakeTelemetryEvent = (name: String, attributes: [String: Any])

@objc(MBEventsManagerSpy)
class MMEEventsManagerSpy: MMEEventsManager {

    private var enqueuedEvents = [FakeTelemetryEvent]()
    private var flushedEvents = [FakeTelemetryEvent]()

    public func reset() {
        enqueuedEvents.removeAll()
        flushedEvents.removeAll()
    }

    override func enqueueEvent(withName name: String) {
        self.enqueueEvent(withName: name, attributes: [:])
    }

    override func enqueueEvent(withName name: String, attributes: [String: Any] = [:]) {
        let event: FakeTelemetryEvent = FakeTelemetryEvent(name: name, attributes: attributes)
        enqueuedEvents.append(event)
    }

    override func sendTurnstileEvent() {
        flushedEvents.append((name: "???", attributes: ["event": MMEEventTypeAppUserTurnstile, "eventsManager": String(describing: self)]))
    }

    override func flush() {
        enqueuedEvents.forEach { (event: FakeTelemetryEvent) in
            flushedEvents.append(event)
        }
    }

    public func hasFlushedEvent(with name: String) -> Bool {
        guard !flushedEvents.contains(where: { $0.name == name }) else {
            return true
        }

        return flushedEvents.contains(where: { (event) -> Bool in
            return event.attributes["event"] as! String == name
        })
    }

    public func hasEnqueuedEvent(with name: String) -> Bool {
        guard !enqueuedEvents.contains(where: { $0.name == name }) else {
            return true
        }

        return enqueuedEvents.contains(where: { (event) -> Bool in
            return event.attributes["event"] as! String == name
        })
    }

    public func enqueuedEventCount(with name: String) -> Int {
        if enqueuedEvents.contains(where: { $0.name == name }) {
            return enqueuedEvents.filter { (event) in
                return event.name == name
            }.count
        }

        return enqueuedEvents.filter { (event) in
            return event.attributes["event"] as! String == name
        }.count
    }

    public func flushedEventCount(with name: String) -> Int {
        if flushedEvents.contains(where: { $0.name == name }) {
            return flushedEvents.filter { (event) in
                return event.name == name
            }.count
        }

        return flushedEvents.filter { (event) in
            return event.attributes["event"] as! String == name
        }.count
    }
}
