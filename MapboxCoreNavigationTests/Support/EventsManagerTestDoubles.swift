import Foundation
import MapboxMobileEvents
@testable import MapboxCoreNavigation
import MapboxDirections

class EventsManagerSpy: EventsManager {
    override var manager: MMEEventsManager {
        get {
            return spy
        }
        set {
            fatalError("Don't do this")
        }
    }

    var spy: MMEEventsManagerSpy = MMEEventsManagerSpy()

    func reset() {
        spy.reset()
    }
}

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
        guard !flushedEvents.contains(where: { $0.name == name }) else {
            return true
        }
        
        return flushedEvents.contains(where: { (event) -> Bool in
            return event.attributes["event"] as! String == name
        })
    }

    public func hasEnqueuedEvent(with name: String) -> Bool {
        guard !enqueuedEvents.contains(where:{ $0.name == name }) else {
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

//class TestNavigationEventsManager: EventsManager {
//    var fakeSource = EventsDataSourceFake()
//    
//    required init(dataSource source: EventsManagerDataSource, accessToken possibleToken: String?) {
//        //fails with either fake or real source
//       super.init(dataSource: source, accessToken: "deadbeef")
//        self.manager = MMEEventsManagerSpy()
//    }
//}
//
//class EventsDataSourceFake: EventsManagerDataSource {
//    static let jsonRoute = (Fixture.JSONFromFileNamed(name: "routeWithInstructions")["routes"] as! [AnyObject]).first as! [String: Any]
//    
//    let testRoute: Route = {
//        let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
//        let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
//        let route = Route(json: EventsDataSourceFake.jsonRoute, waypoints: [waypoint1, waypoint2], options: NavigationRouteOptions(waypoints: [waypoint1, waypoint2]))
//        route.accessToken = "deadbeef"
//        return route
//    }()
//
//    
//    lazy var routeProgress: RouteProgress = RouteProgress(route: testRoute)
//    
//    var usesDefaultUserInterface: Bool = true
//    
//    var location: CLLocation? = CLLocation(latitude: 0.0, longitude: 0.0)
//    
//    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
//    
//    var locationProvider: NavigationLocationManager.Type = NavigationLocationManager.self
//    
//    
//}
