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
        let secondTrace = Fixture.generateTrace(for: secondRoute).shiftedTo(firstTrace.last!.timestamp + 1).qualified()
        
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
        
        let departEvents = eventsManager.debuggableEvents.filter { $0.event == MMEEventTypeNavigationDepart }
        
        XCTAssertTrue(departEvents.count == 2, "There should be two depart events")
        
        let firstDepartEvent = departEvents.sorted(by: { $0.startTimestamp! < $1.startTimestamp! }).first!
        let secondDepartEvent = departEvents.sorted(by: { $0.startTimestamp! > $1.startTimestamp! }).first!
        
        let durationBetweenDepartures = secondDepartEvent.startTimestamp!.timeIntervalSince(firstDepartEvent.startTimestamp!)
        
        XCTAssertTrue(durationBetweenDepartures > 1040, "Second departure should be more than 1040 seconds later than the first departure")
    }
}
