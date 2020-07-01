import XCTest
import MapboxMobileEvents
@testable import TestHelper
@testable import MapboxCoreNavigation

class NavigationEventsManagerTests: XCTestCase {
    func testMobileEventsManagerIsInitializedImmediately() {
        let mobileEventsManagerSpy = MMEEventsManagerSpy()
        let _ = NavigationEventsManager(dataSource: nil, accessToken: "example token", mobileEventsManager: mobileEventsManagerSpy)

        let config = UserDefaults.mme_configuration()
        let token = config.mme_accessToken
        XCTAssertEqual(token, "example token")
    }
    
    func skipped_testDepartRerouteArrive() {
        
        let firstRouteOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 38.853108, longitude: -77.043331),
            CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906),
        ])
        let firstRoute = Fixture.route(from: "DCA-Arboretum", options: firstRouteOptions)
        
        let secondRouteOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 42.361634, longitude: -71.12852),
            CLLocationCoordinate2D(latitude: 42.352396, longitude: -71.068719),
        ])
        let secondRoute = Fixture.route(from: "PipeFittersUnion-FourSeasonsBoston", options: secondRouteOptions)
        
        let firstTrace = Array<CLLocation>(Fixture.generateTrace(for: firstRoute).prefix(upTo: firstRoute.shape!.coordinates.count / 2)).shiftedToPresent().qualified()
        let secondTrace = Fixture.generateTrace(for: secondRoute).shifted(to: firstTrace.last!.timestamp + 1).qualified()
        
        let locationManager = NavigationLocationManager()
        let service = MapboxNavigationService(route: firstRoute,
                                              routeOptions: firstRouteOptions,
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
        
        guard let departEvent = events.filter({ $0.event == MMEEventTypeNavigationDepart }).first else { XCTFail(); return }
        guard let rerouteEvent = events.filter({ $0.event == MMEEventTypeNavigationReroute }).first else { XCTFail(); return }
        guard let arriveEvent = events.filter({ $0.event == MMEEventTypeNavigationArrive }).first else { XCTFail(); return }
        
        let durationBetweenDepartAndArrive = arriveEvent.arrivalTimestamp!.timeIntervalSince(departEvent.startTimestamp!)
        let durationBetweenDepartAndReroute = rerouteEvent.created.timeIntervalSince(departEvent.startTimestamp!)
        let durationBetweenRerouteAndArrive = arriveEvent.arrivalTimestamp!.timeIntervalSince(rerouteEvent.created)
        
        XCTAssertEqual(durationBetweenDepartAndArrive, 1041, accuracy: 1)
        XCTAssertEqual(durationBetweenDepartAndReroute, 225, accuracy: 1)
        XCTAssertEqual(durationBetweenRerouteAndArrive, 816, accuracy: 1)
        XCTAssertEqual(arriveEvent.rerouteCount, 1)
    }
}
