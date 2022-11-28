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
    var locations = [CLLocation]()
    var totalDistanceCompleted: CLLocationDistance = 0

    var arriveAtWaypointCalled = false
    var arriveAtDestinationCalled = false
    var enqueueRerouteEventCalled = false

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
        locations.removeAll()
    }

    func hasImmediateEvent(with eventName: String) -> Bool {
        return eventsAPIMock.hasImmediateEvent(with: eventName)
    }

    func immediateEventCount(with eventName: String) -> Int {
        return eventsAPIMock.immediateEventCount(with: eventName)
    }

    func hasQueuedEvent(with eventName: String) -> Bool {
        return eventsAPIMock.hasQueuedEvent(with: eventName)
    }

    public override func navigationDepartEvent() -> ActiveNavigationEventDetails? {
        if let event = super.navigationDepartEvent() {
            debuggableEvents.append(event)
            return event
        }
        return nil
    }
    
    public override func navigationArriveEvent() -> ActiveNavigationEventDetails? {
        if let event = super.navigationArriveEvent() {
            debuggableEvents.append(event)
            return event
        }
        return nil
    }
    
    public override func navigationRerouteEvent(
        eventType: String = MMEEventTypeNavigationReroute
    ) -> ActiveNavigationEventDetails? {
        if let event = super.navigationRerouteEvent() {
            debuggableEvents.append(event)
            return event
        }
        return nil
    }
    
    public override func createFeedback(screenshotOption: FeedbackScreenshotOption = .automatic) -> FeedbackEvent? {
        let sessionState = SessionState(currentRoute: nil, originalRoute: nil, routeIdentifier: nil)
        var event = PassiveNavigationEventDetails(dataSource: PassiveLocationManager(), sessionState: sessionState)
        event.userIdentifier = UIDevice.current.identifierForVendor?.uuidString
        event.event = MMEEventTypeNavigationFeedback
        return FeedbackEvent(eventDetails: event)
    }

    public override func record(_ locations: [CLLocation]) {
        self.locations.append(contentsOf: locations)
    }

    public override func incrementDistanceTraveled(by distance: CLLocationDistance) {
        totalDistanceCompleted += distance
    }

    public override func arriveAtWaypoint() {
        arriveAtWaypointCalled = true
    }

    public override func arriveAtDestination() {
        arriveAtDestinationCalled = true
    }

    public override func enqueueRerouteEvent() {
        enqueueRerouteEventCalled = true
    }
}
