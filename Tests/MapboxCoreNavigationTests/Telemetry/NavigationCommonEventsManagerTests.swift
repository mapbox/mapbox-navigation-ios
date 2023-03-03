import XCTest
import CoreLocation
@testable import TestHelper
@testable import MapboxCoreNavigation

class NavigationCommonEventsManagerTests: TestCase {
    private var eventManager: NavigationCommonEventsManager!
    private var eventsAPI: EventsAPIMock!
    private var activeNavigationDataSource: ActiveNavigationEventsManagerDataSourceSpy!
    private var passiveNavigationDataSource: PassiveNavigationEventsManagerDataSourceSpy!

    override func setUp() {
        super.setUp()
        eventsAPI = EventsAPIMock()
        activeNavigationDataSource = ActiveNavigationEventsManagerDataSourceSpy()
        passiveNavigationDataSource = PassiveNavigationEventsManagerDataSourceSpy()
        eventManager = NavigationCommonEventsManager(activeNavigationDataSource: activeNavigationDataSource,
                                                     passiveNavigationDataSource: passiveNavigationDataSource,
                                                     accessToken: "fake token",
                                                     eventsAPI: eventsAPI)
    }

    func testTurnstileEventSentUponInitialization() {
        // MARK: it sends a turnstile event upon initialization
        eventsAPI.reset()
        _ = NavigationCommonEventsManager(activeNavigationDataSource: activeNavigationDataSource,
                                          passiveNavigationDataSource: passiveNavigationDataSource,
                                          accessToken: "fake token",
                                          eventsAPI: eventsAPI)
        XCTAssertTrue(eventsAPI.hasImmediateEvent(with: EventType.turnstile.rawValue))
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
        let eventManager = NavigationCommonEventsManager(activeNavigationDataSource: activeNavigationDataSource,
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
        let eventManager = NavigationCommonEventsManager(activeNavigationDataSource: activeNavigationDataSource,
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

    func testSendDepartEvent() {
        let progress = makeRouteProgress()
        eventManager.update(progress: progress)
        XCTAssertTrue(eventsAPI.hasQueuedEvent(with: EventType.depart.rawValue))
        XCTAssertFalse(eventsAPI.hasQueuedEvent(with: EventType.arrive.rawValue))
    }

    func testDoNotSendArriveEventIfUserHasNotArrivedAtWaypoin() {
        let progress = makeRouteProgress()
        eventManager.update(progress: progress)
        eventsAPI.reset()

        eventManager.update(progress: progress)
        XCTAssertFalse(eventsAPI.hasQueuedEvent(with: EventType.arrive.rawValue))
        XCTAssertFalse(eventsAPI.hasQueuedEvent(with: EventType.depart.rawValue))
    }

    func testSendArriveEventIfUserHasArrivedAtWaypoin() {
        let progress = makeRouteProgress()
        eventManager.update(progress: progress)
        eventsAPI.reset()

        progress.currentLegProgress.userHasArrivedAtWaypoint = true
        eventManager.update(progress: progress)
        XCTAssertTrue(eventsAPI.hasQueuedEvent(with: EventType.arrive.rawValue))
        XCTAssertFalse(eventsAPI.hasQueuedEvent(with: EventType.depart.rawValue))
    }

}
