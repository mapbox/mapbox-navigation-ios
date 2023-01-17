import XCTest
import CoreLocation
@testable import TestHelper
@testable import MapboxCoreNavigation

final class ActiveNavigationEventsManagerDataSourceSpy: ActiveNavigationEventsManagerDataSource {
    var routeProgress: MapboxCoreNavigation.RouteProgress = makeRouteProgress()
    var router: MapboxCoreNavigation.Router = RouterSpy(indexedRouteResponse: IndexedRouteResponse(routeResponse: makeRouteResponse(),
                                                                                                   routeIndex: 0),
                                                        dataSource: RouterDataSourceSpy())
    var desiredAccuracy: CLLocationAccuracy = -1
    var locationManagerType: MapboxCoreNavigation.NavigationLocationManager.Type = NavigationLocationManagerSpy.self
}

final class PassiveNavigationEventsManagerDataSourceSpy: PassiveNavigationEventsManagerDataSource {
    var rawLocation: CLLocation? = nil
    var locationManagerType: MapboxCoreNavigation.NavigationLocationManager.Type = NavigationLocationManagerSpy.self
}

class NavigationEventsManagerTests: TestCase {
    private var eventManager: NavigationEventsManager!
    private var eventsAPI: EventsAPIMock!
    private var activeNavigationDataSource: ActiveNavigationEventsManagerDataSourceSpy!
    private var passiveNavigationDataSource: PassiveNavigationEventsManagerDataSourceSpy!

    override func setUp() {
        super.setUp()
        eventsAPI = EventsAPIMock()
        activeNavigationDataSource = ActiveNavigationEventsManagerDataSourceSpy()
        passiveNavigationDataSource = PassiveNavigationEventsManagerDataSourceSpy()
        eventManager = NavigationEventsManager(activeNavigationDataSource: activeNavigationDataSource,
                                               passiveNavigationDataSource: passiveNavigationDataSource,
                                               accessToken: "fake token",
                                               eventsAPI: eventsAPI)
    }

    func testSendCarPlayConnectEventIfDelaysFlushing() {
        eventManager.sendCarPlayConnectEvent()
        XCTAssertTrue(eventsAPI.hasQueuedEvent(with: EventType.carplayConnect.rawValue))
    }

    func testSendCarPlayConnectEventIfDoesNotDelayFlushing() {
        eventManager.delaysEventFlushing = false
        eventManager.sendCarPlayConnectEvent()
        XCTAssertTrue(eventsAPI.hasImmediateEvent(with: EventType.carplayConnect.rawValue))
    }

    func testSendCarPlayDisconnectEventIfDelaysFlushing() {
        eventManager.sendCarPlayDisconnectEvent()
        XCTAssertTrue(eventsAPI.hasQueuedEvent(with: EventType.carplayDisconnect.rawValue))
    }

    func testSendCarPlayDisconnectEventIfDoesNotDelayFlushing() {
        eventManager.delaysEventFlushing = false
        eventManager.sendCarPlayDisconnectEvent()
        XCTAssertTrue(eventsAPI.hasImmediateEvent(with: EventType.carplayDisconnect.rawValue))
    }

    func testSendRouteRetrievalEventIfDelaysFlushing() {
        eventManager.reportReroute(progress: makeRouteProgress(), proactive: false)

        eventManager.sendRouteRetrievalEvent()
        XCTAssertTrue(eventsAPI.hasQueuedEvent(with: EventType.routeRetrieval.rawValue))
    }

    func testSendRouteRetrievalEventIfDoesNotDelayFlushing() {
        eventManager.reportReroute(progress: makeRouteProgress(), proactive: false)
        eventManager.delaysEventFlushing = false

        eventManager.sendRouteRetrievalEvent()
        XCTAssertTrue(eventsAPI.hasImmediateEvent(with: EventType.routeRetrieval.rawValue))
    }

    func testNoDepartEventIfNoDatasource() {
        eventManager.activeNavigationDataSource = nil
        eventManager.sendDepartEvent()
        XCTAssertFalse(eventsAPI.hasQueuedEvent(with: EventType.depart.rawValue))
    }

    func testSendDepartEventIfDelaysFlushing() {
        eventManager.sendDepartEvent()
        XCTAssertTrue(eventsAPI.hasQueuedEvent(with: EventType.depart.rawValue))
    }

    func testSendDepartEventIfDoesNotDelayFlushing() {
        eventManager.delaysEventFlushing = false
        eventManager.sendDepartEvent()
        XCTAssertTrue(eventsAPI.hasImmediateEvent(with: EventType.depart.rawValue))
    }

    func testNoArriveEventIfNoDatasource() {
        eventManager.activeNavigationDataSource = nil
        eventManager.sendArriveEvent()
        XCTAssertFalse(eventsAPI.hasQueuedEvent(with: EventType.arrive.rawValue))
    }

    func testSendArriveEventIfDelaysFlushing() {
        eventManager.sendArriveEvent()
        XCTAssertTrue(eventsAPI.hasQueuedEvent(with: EventType.arrive.rawValue))
    }

    func testSendArriveEventIfDoesNotDelayFlushing() {
        eventManager.delaysEventFlushing = false
        eventManager.sendArriveEvent()
        XCTAssertTrue(eventsAPI.hasImmediateEvent(with: EventType.arrive.rawValue))
    }

    func testNoCancelEventIfNoDatasource() {
        eventManager.activeNavigationDataSource = nil
        eventManager.sendCancelEvent()
        XCTAssertFalse(eventsAPI.hasQueuedEvent(with: EventType.cancel.rawValue))
    }

    func testSendCancelEventIfDelaysFlushing() {
        eventManager.sendCancelEvent()
        XCTAssertTrue(eventsAPI.hasQueuedEvent(with: EventType.cancel.rawValue))
    }

    func testSendCancelEventIfDoesNotDelayFlushing() {
        eventManager.delaysEventFlushing = false
        eventManager.sendCancelEvent()
        XCTAssertTrue(eventsAPI.hasImmediateEvent(with: EventType.cancel.rawValue))
    }

    func testNoPassiveNavigationStartEventIfNoDatasource() {
        let eventManager = NavigationEventsManager(activeNavigationDataSource: activeNavigationDataSource,
                                                   passiveNavigationDataSource: nil,
                                                   accessToken: "fake token",
                                                   eventsAPI: eventsAPI)
        eventManager.sendPassiveNavigationStart()
        XCTAssertFalse(eventsAPI.hasQueuedEvent(with: EventType.freeDrive.rawValue))
    }

    func testSendPassiveNavigationStartEventIfDelaysFlushing() {
        eventManager.sendPassiveNavigationStart()
        XCTAssertTrue(eventsAPI.hasQueuedEvent(with: EventType.freeDrive.rawValue))
    }

    func testSendPassiveNavigationStartEventIfDoesNotDelayFlushing() {
        eventManager.delaysEventFlushing = false
        eventManager.sendPassiveNavigationStart()
        XCTAssertTrue(eventsAPI.hasImmediateEvent(with: EventType.freeDrive.rawValue))
    }

    func testNoPassiveNavigationStopEventIfNoDatasource() {
        let eventManager = NavigationEventsManager(activeNavigationDataSource: activeNavigationDataSource,
                                                   passiveNavigationDataSource: nil,
                                                   accessToken: "fake token",
                                                   eventsAPI: eventsAPI)
        eventManager.sendPassiveNavigationStop()
        XCTAssertFalse(eventsAPI.hasQueuedEvent(with: EventType.freeDrive.rawValue))
    }

    func testSendPassiveNavigationStopEventIfDelaysFlushing() {
        eventManager.sendPassiveNavigationStop()
        XCTAssertTrue(eventsAPI.hasQueuedEvent(with: EventType.freeDrive.rawValue))
    }

    func testSendPassiveNavigationStopEventIfDoesNotDelayFlushing() {
        eventManager.delaysEventFlushing = false
        eventManager.sendPassiveNavigationStop()
        XCTAssertTrue(eventsAPI.hasImmediateEvent(with: EventType.freeDrive.rawValue))
    }

    func testSendFeedbackEventIfDelaysFlushing() {
        let coreEvent = CoreFeedbackEvent(timestamp: Date(), eventDictionary: ["event":"feedback"])
        eventManager.sendFeedbackEvents([coreEvent])
        XCTAssertTrue(eventsAPI.hasQueuedEvent(with: "feedback"))
    }

    func testSendFeedbackEventIfDoesNotDelayFlushing() {
        eventManager.delaysEventFlushing = false
        let coreEvent = CoreFeedbackEvent(timestamp: Date(), eventDictionary: ["event":"feedback"])
        eventManager.sendFeedbackEvents([coreEvent])
        XCTAssertTrue(eventsAPI.hasImmediateEvent(with: "feedback"))
    }

    func skipped_testDepartRerouteArrive() {
        
        let firstRouteOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 38.853108, longitude: -77.043331),
            CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906),
        ])
        let firstRoute = Fixture.route(from: "DCA-Arboretum", options: firstRouteOptions)
        let firstRouteResponse = IndexedRouteResponse(routeResponse: Fixture.routeResponse(from: "DCA-Arboretum", options: firstRouteOptions),
                                                      routeIndex: 0)
        
        let secondRouteOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 42.361634, longitude: -71.12852),
            CLLocationCoordinate2D(latitude: 42.352396, longitude: -71.068719),
        ])
        let secondRoute = Fixture.route(from: "PipeFittersUnion-FourSeasonsBoston", options: secondRouteOptions)
        let secondRouteResponse = Fixture.routeResponse(from: "PipeFittersUnion-FourSeasonsBoston", options: secondRouteOptions)
        
        let firstTrace = Array<CLLocation>(Fixture.generateTrace(for: firstRoute).prefix(upTo: firstRoute.shape!.coordinates.count / 2)).shiftedToPresent().qualified()
        let secondTrace = Fixture.generateTrace(for: secondRoute).shifted(to: firstTrace.last!.timestamp + 1).qualified()
        
        let locationManager = NavigationLocationManager()
        let service = MapboxNavigationService(indexedRouteResponse: firstRouteResponse,
                                              customRoutingProvider: MapboxRoutingProvider(.offline),
                                              credentials: Fixture.credentials,
                                              locationSource: locationManager,
                                              eventsManagerType: NavigationEventsManagerSpy.self,
                                              simulating: .always)
        service.start()
        
        for location in firstTrace {
            service.router.locationManager!(locationManager, didUpdateLocations: [location])
        }

        let routeUpdated = expectation(description: "Route Updated")
        service.router.updateRoute(with: .init(routeResponse: secondRouteResponse, routeIndex: 0), routeOptions: nil) {
            success in
            XCTAssertTrue(success)
            routeUpdated.fulfill()
        }
        wait(for: [routeUpdated], timeout: 1)
        
        for location in secondTrace {
            service.router.locationManager!(locationManager, didUpdateLocations: [location])
        }
        
        let eventsManager = service.eventsManager as! NavigationEventsManagerSpy
        let events = eventsManager.debuggableEvents
        
        XCTAssertEqual(events.count, 3, "There should be one depart, one reroute, and one arrive event.")
        
        guard let departEvent = events.filter({ $0.event == EventType.depart.rawValue }).first else { XCTFail(); return }
        guard let rerouteEvent = events.filter({ $0.event == EventType.reroute.rawValue }).first else { XCTFail(); return }
        guard let arriveEvent = events
            .filter({ $0.event == EventType.arrive.rawValue })
            .first as? ActiveNavigationEventDetails else { XCTFail(); return }
        
        let durationBetweenDepartAndArrive = arriveEvent.arrivalTimestamp!.timeIntervalSince(departEvent.startTimestamp!)
        let durationBetweenDepartAndReroute = rerouteEvent.created.timeIntervalSince(departEvent.startTimestamp!)
        let durationBetweenRerouteAndArrive = arriveEvent.arrivalTimestamp!.timeIntervalSince(rerouteEvent.created)
        
        XCTAssertEqual(durationBetweenDepartAndArrive, 1041, accuracy: 1)
        XCTAssertEqual(durationBetweenDepartAndReroute, 225, accuracy: 1)
        XCTAssertEqual(durationBetweenRerouteAndArrive, 816, accuracy: 1)
        XCTAssertEqual(arriveEvent.rerouteCount, 1)
    }
    
    // Test allows to verify whether no Main Thread Checker errors occur during
    // NavigationEventDetails object creation.
    func testNavigationEventDetailsGlobalQueue() {
        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 38.853108, longitude: -77.043331),
            CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906),
        ])
        let eventTimeout = 0.3
        let route = Fixture.route(from: "DCA-Arboretum", options: routeOptions)
        let routeResponse = IndexedRouteResponse(routeResponse: Fixture.routeResponse(from: "DCA-Arboretum", options: routeOptions),
                                                 routeIndex: 0)
        let dataSource = MapboxNavigationService(indexedRouteResponse: routeResponse,
                                                 customRoutingProvider: MapboxRoutingProvider(.offline),
                                                 credentials: Fixture.credentials,
                                                 simulating: .onPoorGPS)
        let sessionState = SessionState(currentRoute: route, originalRoute: route, routeIdentifier: routeResponse.routeResponse.identifier)
        
        // Attempt to create NavigationEventDetails object from global queue, no errors from Main Thread Checker
        // are expected.
        let expectation = XCTestExpectation()
        DispatchQueue.global().async {
            let _ = ActiveNavigationEventDetails(dataSource: dataSource, session: sessionState, defaultInterface: false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: eventTimeout)
        
        // Sanity check to verify that no issues occur when creating NavigationEventDetails from main queue.
        let _ = ActiveNavigationEventDetails(dataSource: dataSource, session: sessionState, defaultInterface: false)
    }
}
