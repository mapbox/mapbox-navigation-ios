import Foundation
import MapboxMobileEvents
@testable import MapboxCoreNavigation
import MapboxDirections
#if SWIFT_PACKAGE
import CTestHelper
#endif

public class NavigationEventsManagerSpy: NavigationEventsManager {
    var mobileEventsManagerSpy: MMEEventsManagerSpy!
    
    var _enqueuedEvents: [FakeTelemetryEvent] {
        return mobileEventsManagerSpy.enqueuedEvents
    }
    
    var _flushedEvents: [FakeTelemetryEvent] {
        return mobileEventsManagerSpy.flushedEvents
    }
    
    var debuggableEvents = [NavigationEventDetails]()

    required public init() {
        mobileEventsManagerSpy = MMEEventsManagerSpy.testableInstance()
        super.init(activeNavigationDataSource: nil, accessToken: "fake token", mobileEventsManager: mobileEventsManagerSpy)
    }
    
    required convenience init(activeNavigationDataSource: ActiveNavigationEventsManagerDataSource? = nil,
                  passiveNavigationDataSource: PassiveNavigationEventsManagerDataSource? = nil,
                  accessToken possibleToken: String? = nil,
                  mobileEventsManager: MMEEventsManager = .shared()) {
        self.init()
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
    
    override public func navigationDepartEvent() -> ActiveNavigationEventDetails? {
        if let event = super.navigationDepartEvent() {
            debuggableEvents.append(event)
            return event
        }
        return nil
    }
    
    override public func navigationArriveEvent() -> ActiveNavigationEventDetails? {
        if let event = super.navigationArriveEvent() {
            debuggableEvents.append(event)
            return event
        }
        return nil
    }
    
    override public func navigationRerouteEvent(
        eventType: String = MMEEventTypeNavigationReroute
    ) -> ActiveNavigationEventDetails? {
        if let event = super.navigationRerouteEvent() {
            debuggableEvents.append(event)
            return event
        }
        return nil
    }
    
    override public func createFeedback(screenshotOption: FeedbackScreenshotOption = .automatic) -> FeedbackEvent? {
        let sessionState = SessionState(currentRoute: nil, originalRoute: nil, routeIdentifier: nil)
        var event = PassiveNavigationEventDetails(dataSource: PassiveLocationManager(), sessionState: sessionState)
        event.userIdentifier = UIDevice.current.identifierForVendor?.uuidString
        event.event = MMEEventTypeNavigationFeedback
        return FeedbackEvent(eventDetails: event)
    }
}

typealias FakeTelemetryEvent = (name: String, attributes: [String: Any])

class MMEEventsManagerSpy: MMEEventsManager {
    var enqueuedEvents = [FakeTelemetryEvent]()
    var flushedEvents = [FakeTelemetryEvent]()

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
        enqueuedEvents.removeAll()
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
