import XCTest
import MapboxMobileEvents
@testable import TestHelper
@testable import MapboxCoreNavigation


class NavigationEventsManagerTests: XCTestCase {

    func testMobileEventsManagerIsInitializedImmediately() {
        let mobileEventsManagerSpy = MMEEventsManagerSpy()
        let _ = NavigationEventsManager(dataSource: nil, accessToken: "example token", mobileEventsManager: mobileEventsManagerSpy)

        XCTAssertEqual(mobileEventsManagerSpy.accessToken, "example token")
    }
    
    func testDepartRerouteArrive() {
        
        let firstRoute = Fixture.route(from: "DCA-Arboretum")
        let secondRoute = Fixture.route(from: "PipeFittersUnion-FourSeasonsBoston")
        
        let firstTrace = Array<CLLocation>(Fixture.generateTrace(for: firstRoute).prefix(upTo: firstRoute.coordinates!.count / 2)).shiftedToPresent().qualified()
        let secondTrace = Fixture.generateTrace(for: secondRoute).shifted(to: firstTrace.last!.timestamp + 1).qualified()
        
        let locationManager = NavigationLocationManager()
        let service = MapboxNavigationService(route: firstRoute,
                                              directions: nil,
                                              locationSource: locationManager,
                                              eventsManagerType: NavigationEventsManagerSpy.self,
                                              simulating: .always)
        service.start()
        
        for location in firstTrace {
            service.router.locationManager!(locationManager, didUpdateLocations: [location])
        }
        
        service.route = secondRoute
        
        for location in secondTrace {
            service.router.locationManager!(locationManager, didUpdateLocations: [location])
        }
        
        let eventsManager = service.eventsManager as! NavigationEventsManagerSpy
        let events = eventsManager.debuggableEvents
        
        XCTAssertEqual(events.count, 3, "There should be one depart, one reroute, and one arrive event.")
        
        let departEvent = events.filter { $0.event == MMEEventTypeNavigationDepart }.first!
        let rerouteEvent = events.filter { $0.event == MMEEventTypeNavigationReroute }.first!
        let arriveEvent = events.filter { $0.event == MMEEventTypeNavigationArrive }.first!
        
        let durationBetweenDepartAndArrive = arriveEvent.arrivalTimestamp!.timeIntervalSince(departEvent.startTimestamp!)
        let durationBetweenDepartAndReroute = rerouteEvent.created.timeIntervalSince(departEvent.startTimestamp!)
        let durationBetweenRerouteAndArrive = arriveEvent.arrivalTimestamp!.timeIntervalSince(rerouteEvent.created)
        
        XCTAssertEqual(Int(round(durationBetweenDepartAndArrive)), 1041)
        XCTAssertEqual(Int(round(durationBetweenDepartAndReroute)), 225)
        XCTAssertEqual(Int(round(durationBetweenRerouteAndArrive)), 816)
        XCTAssertEqual(arriveEvent.rerouteCount, 1)
    }
}
