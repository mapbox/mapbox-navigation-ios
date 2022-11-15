import Foundation
@testable import MapboxCoreNavigation
#if SWIFT_PACKAGE
import CTestHelper
#endif

public class PassiveNavigationDataSourceSpy: PassiveNavigationEventsManagerDataSource {
    public var rawLocation: CLLocation? = nil
    public var locationManagerType: MapboxCoreNavigation.NavigationLocationManager.Type = NavigationLocationManagerSpy.self
}

public class NavigationEventsManagerSpy: NavigationEventsManager {
    private let eventsAPIMock: EventsAPIMock
    private let passiveNavigationDataSource: PassiveNavigationDataSourceSpy
    
    var debuggableEvents = [NavigationEventDetails]()

    required public init() {
        eventsAPIMock = EventsAPIMock()
        passiveNavigationDataSource = PassiveNavigationDataSourceSpy()
        super.init(activeNavigationDataSource: nil,
                   passiveNavigationDataSource: passiveNavigationDataSource,
                   accessToken: "fake token",
                   eventsAPI: eventsAPIMock)
    }

    required convenience init(activeNavigationDataSource: ActiveNavigationEventsManagerDataSource? = nil, passiveNavigationDataSource: PassiveNavigationEventsManagerDataSource? = nil, accessToken possibleToken: String? = nil) {
        self.init()
    }

    func reset() {
        eventsAPIMock.reset()
    }

    func hasImmediateEvent(with eventName: String) -> Bool {
        return eventsAPIMock.hasImmediateEvent(with: eventName)
    }

    func immediateEventCount(with eventName: String) -> Int {
        return eventsAPIMock.immediateEventCount(with: eventName)
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
