import Foundation
import MapboxMobileEvents
@_implementationOnly import MapboxCommon_Private
@testable import MapboxCoreNavigation
import MapboxDirections
#if SWIFT_PACKAGE
import CTestHelper
#endif

public class NavigationEventsManagerSpy: NavigationEventsManager {
    var eventsServiceSpy: EventsServiceSpy!
    
    var _sentEvents: [FakeTelemetryEvent] {
        return eventsServiceSpy.sentEvents
    }
    
    var debuggableEvents = [NavigationEventDetails]()

    required public init() {
        eventsServiceSpy = EventsServiceSpy.testableInstance()
        super.init(activeNavigationDataSource: nil, accessToken: "fake token", coreTelemetry: eventsServiceSpy)
    }
    
    required convenience init(activeNavigationDataSource: ActiveNavigationEventsManagerDataSource? = nil,
                  passiveNavigationDataSource: PassiveNavigationEventsManagerDataSource? = nil,
                  accessToken possibleToken: String? = nil,
                  coreTelemetry: AnyObject? = nil) {
        self.init()
    }

    func reset() {
        eventsServiceSpy.reset()
    }

    func hasSentEvent(with eventName: String) -> Bool {
        return eventsServiceSpy.hasSentEvent(with: eventName)
    }

    func sentEventCount(with eventName: String) -> Int {
        return eventsServiceSpy.sentEventCount(with: eventName)
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

typealias FakeTelemetryEvent = (priority: EventPriority, attributes: [String: Any])

class EventsServiceSpy: EventsService {
    var sentEvents = [FakeTelemetryEvent]()

    public func reset() {
        sentEvents.removeAll()
    }

    override func sendEvent(for event: Event, callback: EventsServiceResponseCallback? = nil) {
        let event: FakeTelemetryEvent = FakeTelemetryEvent(priority: event.priority, attributes: event.attributes as! [String: Any])
        sentEvents.append(event)
    }
    
    override func sendTurnstileEvent(for turnstileEvent: TurnstileEvent, callback: EventsServiceResponseCallback? = nil) {
        let event: FakeTelemetryEvent = FakeTelemetryEvent(priority: .immediate, attributes: ["event": MMEEventTypeAppUserTurnstile, "eventsManager": String(describing: self)])
        sentEvents.append(event)
    }

    public func hasSentEvent(with name: String) -> Bool {
        return sentEvents.contains(where: { (event) -> Bool in
            return event.attributes["event"] as! String == name
        })
    }

    public func sentEventCount(with name: String) -> Int {
        return sentEvents.filter { (event) in
            return event.attributes["event"] as! String == name
        }.count
    }
}
