import Foundation
import XCTest
import CoreLocation
import TestHelper
import MapboxNavigationNative
import MapboxDirections
@testable import MapboxCoreNavigation

final class BillingHandlerTests: TestCase {
    private var billingService: BillingServiceMock!
    private var handler: BillingHandler!
    private var sessionUuid: UUID!
    private var freeRideToken: String!
    private var activeGuidanceToken: String!
    private var navigator: MapboxCoreNavigation.Navigator? = nil

    override func setUp() {
        super.setUp()

        sessionUuid = UUID()
        freeRideToken = UUID().uuidString
        activeGuidanceToken = UUID().uuidString
        billingService = .init()
        handler = BillingHandler.__createMockedHandler(with: billingService)
        billingService.onGetSKUTokenIfValid = { [unowned self] sessionType in
            switch sessionType {
            case .activeGuidance: return activeGuidanceToken
            case .freeDrive: return freeRideToken
            }
        }
        navigator = Navigator.shared
    }

    override func tearDown() {
        super.tearDown()
        billingService = nil
        handler = nil
        navigator = nil
    }

    func testSessionStop() {
        let cancelSessionCalled = expectation(description: "Cancel session called")
        let billingEventTriggered = expectation(description: "Billing event triggered")
        billingService.onTriggerBillingEvent = { _ in
            billingEventTriggered.fulfill()
        }
        billingService.onStopBillingSession = { _ in
            cancelSessionCalled.fulfill()
        }

        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .stopped)

        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)

        DispatchQueue.main.async() { [unowned self] in
            handler.stopBillingSession(with: self.sessionUuid)
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .stopped)

        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
            .stopBillingSession(.activeGuidance),
        ])
    }

    func testSessionStart() {
        let expectedSessionType = BillingHandler.SessionType.activeGuidance
        let billingEventTriggered = expectation(description: "Billing event triggered")
        let beginSessionTriggered = expectation(description: "Beging session triggered")
        billingService.onStopBillingSession = { _ in
            XCTFail("Cancel shouldn't be called")
        }
        billingService.onBeginBillingSession = { sessionType, _ in
            beginSessionTriggered.fulfill()
            XCTAssertEqual(sessionType, expectedSessionType)
        }

        billingService.onTriggerBillingEvent = { _ in
            billingEventTriggered.fulfill()
        }

        handler.beginBillingSession(for: expectedSessionType, uuid: sessionUuid)
        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .running)
        waitForExpectations(timeout: 1, handler: nil)

        billingService.assertEvents([
            .beginBillingSession(expectedSessionType),
        ])
    }

    func testSessionPause() {
        let sessionStarted = expectation(description: "Session started")
        let sessionPaused = expectation(description: "Session paused")
        billingService.onBeginBillingSession = { _, _ in
            sessionStarted.fulfill()
        }
        billingService.onPauseBillingSession = { _ in
            sessionPaused.fulfill()
        }

        handler.beginBillingSession(for: .freeDrive, uuid: sessionUuid)
        handler.pauseBillingSession(with: sessionUuid)
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .paused)
        let billingSessionResumed = expectation(description: "Billing session resumed")
        billingService.onResumeBillingSession = { _, _ in
            billingSessionResumed.fulfill()
        }

        handler.resumeBillingSession(with: sessionUuid)
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .running)


        billingService.assertEvents([
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive),
            .resumeBillingSession(.freeDrive),
        ])
    }

    func testSessionResumeFailed() {
        let expectedSessionType = BillingHandler.SessionType.activeGuidance
        let sessionStarted = expectation(description: "Session started")
        sessionStarted.expectedFulfillmentCount = 2
        billingService.onBeginBillingSession = { sessionType, _ in
            sessionStarted.fulfill()
            XCTAssertEqual(sessionType, expectedSessionType)
        }
        billingService.onResumeBillingSession = { _, onError in
            DispatchQueue.global().async {
                onError(.resumeFailed)
            }
        }

        handler.beginBillingSession(for: expectedSessionType, uuid: sessionUuid)
        handler.pauseBillingSession(with: sessionUuid)
        handler.resumeBillingSession(with: sessionUuid)
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .running)


        billingService.assertEvents([
            .beginBillingSession(expectedSessionType),
            .pauseBillingSession(expectedSessionType),
            .resumeBillingSession(expectedSessionType),
            .beginBillingSession(expectedSessionType),
        ])
    }

    func testSessionBeginFailed() {
        let sessionFailed = expectation(description: "Session Failed")
        billingService.onBeginBillingSession = { _, onError in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                onError(.unknown)
                sessionFailed.fulfill()
            }
        }
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)
        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .running)
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .stopped)

        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
        ])
    }

    func testFailedMauBillingDoNotStopSession() {
        let billingEventTriggered = expectation(description: "Billing event triggered")
        let beginSessionTriggered = expectation(description: "Begin session triggered")
        billingService.onTriggerBillingEvent = { onError in
            DispatchQueue.global().async {
                onError(.tokenValidationFailed)
                billingEventTriggered.fulfill()
            }
        }
        billingService.onBeginBillingSession = { _, _ in
            beginSessionTriggered.fulfill()
        }
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertEqual(handler.sessionState(uuid: sessionUuid), .running)

        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
        ])
    }

    /// If two sessions starts, one after another, and then the first one stopped, the billing session should continue.
    func testTwoSessionsWithOneStopped() {
        let finished = expectation(description: "Finished")
        let queue = DispatchQueue(label: "")
        queue.async {
            self.handler.beginBillingSession(for: .freeDrive, uuid: UUID())
        }
        queue.async {
            self.handler.beginBillingSession(for: .activeGuidance, uuid: self.sessionUuid)
            queue.async {
                self.handler.stopBillingSession(with: self.sessionUuid)
                finished.fulfill()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)

        billingService.assertEvents([
            .beginBillingSession(.freeDrive),
            .beginBillingSession(.activeGuidance),
            .stopBillingSession(.activeGuidance)
        ])
    }

    func testTwoSessionsWithResumeFailed() {
        let sessionStarted = expectation(description: "Session started")
        let sessionStopped = expectation(description: "Session stopped")
        sessionStarted.expectedFulfillmentCount = 3
        sessionStopped.expectedFulfillmentCount = 2
        billingService.onBeginBillingSession = { _, onError in
            sessionStarted.fulfill()
        }
        billingService.onStopBillingSession = { _ in
            sessionStopped.fulfill()
        }
        billingService.onResumeBillingSession = { _, onError in
            onError(.resumeFailed)
        }
        let queue = DispatchQueue(label: "")
        let freeDriveSessionUUID = UUID()
        let activeGuidanceSessionUUID = UUID()

        queue.async {
            self.handler.beginBillingSession(for: .freeDrive, uuid: freeDriveSessionUUID)
        }
        queue.async {
            self.handler.beginBillingSession(for: .activeGuidance, uuid: activeGuidanceSessionUUID)
        }
        queue.async {
            self.handler.pauseBillingSession(with: activeGuidanceSessionUUID)
        }
        queue.async {
            self.handler.resumeBillingSession(with: activeGuidanceSessionUUID)
        }
        queue.async {
            self.handler.stopBillingSession(with: activeGuidanceSessionUUID)
        }
        queue.async {
            self.handler.stopBillingSession(with: freeDriveSessionUUID)
        }
        waitForExpectations(timeout: 5, handler: nil)
        billingService.assertEvents([
            .beginBillingSession(.freeDrive),
            .beginBillingSession(.activeGuidance),
            .pauseBillingSession(.activeGuidance),
            .resumeBillingSession(.activeGuidance),
            .beginBillingSession(.activeGuidance),
            .stopBillingSession(.activeGuidance),
            .stopBillingSession(.freeDrive),
        ])
    }

    func testPausedPassiveLocationManagerDoNotUpdateStatus() {
        let updatesSpy = PassiveLocationManagerDelegateSpy()

        let locations = Array<CLLocation>.locations(from: "sthlm-double-back-replay").shiftedToPresent()
        let locationManager = ReplayLocationManager(locations: locations)
        locationManager.replayCompletionHandler = { _ in true }

        let passiveLocationManager = PassiveLocationManager(directions: DirectionsSpy(),
                                                            systemLocationManager: locationManager)

        locationManager.delegate = passiveLocationManager
        passiveLocationManager.delegate = updatesSpy
        passiveLocationManager.pauseTripSession()

        locationManager.replayCompletionHandler = { _ in true }
        locationManager.speedMultiplier = 30
        updatesSpy.onProgressUpdate = { _,_ in
            XCTFail("Updated on paused session isn't allowed")
        }
        locationManager.startUpdatingLocation()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        billingServiceMock.assertEvents([
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive)
        ])

        XCTAssertNil(passiveLocationManager.rawLocation, "Location updates should be blocked")

        updatesSpy.onProgressUpdate = nil
        passiveLocationManager.resumeTripSession()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        XCTAssertNotNil(passiveLocationManager.rawLocation)
        locationManager.stopUpdatingLocation()
    }

    func testTokens() {
        let freeDriveSessionUUID = UUID()
        let activeGuidanceSessionUUID = UUID()
        handler.beginBillingSession(for: .freeDrive, uuid: freeDriveSessionUUID)
        XCTAssertEqual(handler.serviceSkuToken, freeRideToken)
        handler.beginBillingSession(for: .activeGuidance, uuid: activeGuidanceSessionUUID)
        XCTAssertEqual(handler.serviceSkuToken, activeGuidanceToken)
        handler.pauseBillingSession(with: activeGuidanceSessionUUID)
        XCTAssertEqual(handler.serviceSkuToken, freeRideToken)
        handler.pauseBillingSession(with: freeDriveSessionUUID)
        XCTAssertEqual(handler.serviceSkuToken, "")
        handler.resumeBillingSession(with: freeDriveSessionUUID)
        XCTAssertEqual(handler.serviceSkuToken, freeRideToken)
        handler.resumeBillingSession(with: activeGuidanceSessionUUID)
        XCTAssertEqual(handler.serviceSkuToken, activeGuidanceToken)
        handler.stopBillingSession(with: activeGuidanceSessionUUID)
        XCTAssertEqual(handler.serviceSkuToken, freeRideToken)
        handler.stopBillingSession(with: freeDriveSessionUUID)
        XCTAssertEqual(handler.serviceSkuToken, "")
    }

    func testStartingFreeRideAfterActiveGuidance() {
        handler.beginBillingSession(for: .activeGuidance, uuid: .init())
        XCTAssertEqual(handler.serviceSkuToken, activeGuidanceToken)
        handler.beginBillingSession(for: .freeDrive, uuid: .init())
        XCTAssertEqual(handler.serviceSkuToken, activeGuidanceToken)
    }

    func testSessionStoppedForNonExistingUUID() {
        XCTAssertEqual(billingService.getSessionStatus(for: .activeGuidance), .stopped)
        XCTAssertEqual(handler.sessionState(uuid: UUID()), .stopped)
    }

    func testOneBillingSessionForTwoSameRideSession() {
        let session1UUID = UUID()
        let session2UUID = UUID()
        handler.beginBillingSession(for: .activeGuidance, uuid: session1UUID)
        handler.beginBillingSession(for: .activeGuidance, uuid: session2UUID)
        XCTAssertEqual(billingService.getSessionStatus(for: .activeGuidance), .running)
        handler.stopBillingSession(with: session1UUID)
        XCTAssertEqual(handler.sessionState(uuid: session1UUID), .stopped)
        XCTAssertEqual(handler.sessionState(uuid: session2UUID), .running)
        XCTAssertEqual(billingService.getSessionStatus(for: .activeGuidance), .running)
        handler.stopBillingSession(with: session2UUID)
        XCTAssertEqual(handler.sessionState(uuid: session2UUID), .stopped)
        XCTAssertEqual(billingService.getSessionStatus(for: .activeGuidance), .stopped)

        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
            .stopBillingSession(.activeGuidance)
        ])
    }

    func testTwoBillingSessionForTwoSameRideSession() {
        let activeGuidanceSession1UUID = UUID()
        let activeGuidanceSession2UUID = UUID()
        let freeRideSession1UUID = UUID()
        let freeRideSession2UUID = UUID()

        handler.beginBillingSession(for: .activeGuidance, uuid: activeGuidanceSession1UUID)
        handler.beginBillingSession(for: .activeGuidance, uuid: activeGuidanceSession2UUID)
        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession1UUID)
        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession2UUID)
        handler.stopBillingSession(with: activeGuidanceSession1UUID)
        handler.stopBillingSession(with: activeGuidanceSession2UUID)
        handler.stopBillingSession(with: freeRideSession2UUID)
        handler.stopBillingSession(with: freeRideSession1UUID)

        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
            .beginBillingSession(.freeDrive),
            .stopBillingSession(.activeGuidance),
            .stopBillingSession(.freeDrive)
        ])
    }

    /// A test case with quite complex configuration
    func testComplexUsecase() {
        let activeGuidanceSession1UUID = UUID()
        let activeGuidanceSession2UUID = UUID()
        let freeRideSession1UUID = UUID()
        let freeRideSession2UUID = UUID()

        handler.beginBillingSession(for: .activeGuidance, uuid: activeGuidanceSession1UUID)
        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession1UUID)
        handler.beginBillingSession(for: .activeGuidance, uuid: activeGuidanceSession2UUID)
        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession2UUID)
        handler.pauseBillingSession(with: freeRideSession1UUID)
        handler.pauseBillingSession(with: activeGuidanceSession1UUID)
        handler.resumeBillingSession(with: activeGuidanceSession1UUID)
        handler.resumeBillingSession(with: freeRideSession1UUID)
        handler.pauseBillingSession(with: freeRideSession1UUID)
        handler.pauseBillingSession(with: freeRideSession2UUID)
        handler.resumeBillingSession(with: freeRideSession1UUID)
        handler.stopBillingSession(with: activeGuidanceSession1UUID)
        handler.stopBillingSession(with: activeGuidanceSession2UUID)
        handler.pauseBillingSession(with: freeRideSession1UUID)
        handler.pauseBillingSession(with: freeRideSession2UUID)
        handler.stopBillingSession(with: freeRideSession2UUID)
        handler.stopBillingSession(with: freeRideSession1UUID)

        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive),
            .resumeBillingSession(.freeDrive),
            .stopBillingSession(.activeGuidance),
            .pauseBillingSession(.freeDrive),
            .stopBillingSession(.freeDrive),
        ])
    }

    func testRouteChangeCloseToOriginal() {
        runRouteChangeTest(
            initialRouteWaypoints: [
                CLLocationCoordinate2D(latitude: 59.337928, longitude: 18.076841),
                CLLocationCoordinate2D(latitude: 59.347928, longitude: 18.086841),
            ],
            newRouteWaypoints: [
                CLLocationCoordinate2D(latitude: 59.337928, longitude: 18.076841),
                CLLocationCoordinate2D(latitude: 59.347929, longitude: 18.086842),
            ],
            expectedEvents: [
                .beginBillingSession(.activeGuidance),
            ]
        )
    }

    func testRouteChangeDifferentToOriginal() {
        runRouteChangeTest(
            initialRouteWaypoints: [
                CLLocationCoordinate2D(latitude: 59.337928, longitude: 18.076841),
                CLLocationCoordinate2D(latitude: 59.347928, longitude: 18.086841),
            ],
            newRouteWaypoints: [
                CLLocationCoordinate2D(latitude: 59.337928, longitude: 18.076841),
                CLLocationCoordinate2D(latitude: 60.347929, longitude: 18.086841),
            ],
            expectedEvents: [
                .beginBillingSession(.activeGuidance),
                .stopBillingSession(.activeGuidance),
                .beginBillingSession(.activeGuidance),
            ]
        )
    }

    func testRouteChangeCloseToOriginalMultileg() {
        runRouteChangeTest(
            initialRouteWaypoints: [
                CLLocationCoordinate2D(latitude: 59.337928, longitude: 18.076841),
                CLLocationCoordinate2D(latitude: 59.347928, longitude: 18.086841),
                CLLocationCoordinate2D(latitude: 59.357928, longitude: 18.086841),
                CLLocationCoordinate2D(latitude: 59.367928, longitude: 18.086841),
            ],
            newRouteWaypoints: [
                CLLocationCoordinate2D(latitude: 59.337928, longitude: 18.076841),
                CLLocationCoordinate2D(latitude: 59.347929, longitude: 18.086841),
                CLLocationCoordinate2D(latitude: 59.357929, longitude: 18.086841),
                CLLocationCoordinate2D(latitude: 59.367929, longitude: 18.086841),
            ],
            expectedEvents: [
                .beginBillingSession(.activeGuidance),
            ]
        )
    }

    func testPauseSessionWithStoppingSimilarOne() {
        let freeRideSession1UUID = UUID()
        let freeRideSession2UUID = UUID()

        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession1UUID)
        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession2UUID)
        handler.pauseBillingSession(with: freeRideSession1UUID)
        handler.stopBillingSession(with: freeRideSession2UUID)

        billingService.assertEvents([
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive),
        ])
    }

    func testBeginSessionWithPausedSimilarOne() {
        let freeRideSession1UUID = UUID()
        let freeRideSession2UUID = UUID()

        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession1UUID)
        handler.pauseBillingSession(with: freeRideSession1UUID)
        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession2UUID)

        billingService.assertEvents([
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive),
            .resumeBillingSession(.freeDrive)
        ])
    }

    func testBeginSessionWithPausedSimilarOneButFailed() {
        let freeRideSession1UUID = UUID()
        let freeRideSession2UUID = UUID()

        let resumeFailedCalled = expectation(description: "Resume Failed Called")
        billingService.onResumeBillingSession = { _, onError in
            DispatchQueue.global().async {
                onError(.resumeFailed)
                DispatchQueue.global().async {
                    resumeFailedCalled.fulfill()
                }
            }
        }

        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession1UUID)
        handler.pauseBillingSession(with: freeRideSession1UUID)
        handler.beginBillingSession(for: .freeDrive, uuid: freeRideSession2UUID)

        waitForExpectations(timeout: 1, handler: nil)

        billingService.assertEvents([
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive),
            .resumeBillingSession(.freeDrive),
            .beginBillingSession(.freeDrive),
        ])
    }


    private func runRouteChangeTest(initialRouteWaypoints: [CLLocationCoordinate2D],
                                    newRouteWaypoints: [CLLocationCoordinate2D],
                                    expectedEvents: [BillingServiceMock.Event]) {
        precondition(initialRouteWaypoints.count % 2 == 0)

        final class DataSource: RouterDataSource {
            var locationManagerType: NavigationLocationManager.Type {
                NavigationLocationManager.self
            }
        }

        let (initialRouteResponse, _) = Fixture.route(waypoints: initialRouteWaypoints)
        let (newRouteResponse, _) = Fixture.route(waypoints: newRouteWaypoints)

        let dataSource = DataSource()
        let routeController = RouteController(indexedRouteResponse: IndexedRouteResponse(routeResponse: initialRouteResponse, routeIndex: 0),
                                              customRoutingProvider: MapboxRoutingProvider(.offline),
                                              dataSource: dataSource)

        let routeUpdated = expectation(description: "Route updated")
        routeController.updateRoute(with: IndexedRouteResponse(routeResponse: newRouteResponse,
                                                               routeIndex: 0),
                                    routeOptions: NavigationRouteOptions(coordinates: newRouteWaypoints)) { success in
            XCTAssertTrue(success)
            routeUpdated.fulfill()
        }
        wait(for: [routeUpdated], timeout: 10)
        billingServiceMock.assertEvents(expectedEvents)
    }

    func testServiceAccessToken() {
        let expectedAccessToken = UUID().uuidString
        billingServiceMock.accessToken = expectedAccessToken
        XCTAssertEqual(Accounts.serviceAccessToken, expectedAccessToken)
    }

    func testForceStartNewBillingSession() {
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)
        handler.beginNewBillingSessionIfExists(with: sessionUuid)
        
        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
            .beginBillingSession(.activeGuidance),
        ])
    }

    func testForceStartNewBillingSessionOnPausedSession() {
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)
        handler.pauseBillingSession(with: sessionUuid)
        handler.beginNewBillingSessionIfExists(with: sessionUuid)
        handler.resumeBillingSession(with: sessionUuid)

        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
            .pauseBillingSession(.activeGuidance),
            .beginBillingSession(.activeGuidance),
            .pauseBillingSession(.activeGuidance),
            .resumeBillingSession(.activeGuidance),
        ])
    }

    func testForceStartNewBillingSessionOnNonExistentSession() {
        handler.beginNewBillingSessionIfExists(with: sessionUuid)

        billingService.assertEvents([
        ])
    }

    func testForceStartNewBillingSessionOnPausedSessionFreeDrive() {
        handler.beginBillingSession(for: .freeDrive, uuid: sessionUuid)
        handler.pauseBillingSession(with: sessionUuid)
        handler.beginNewBillingSessionIfExists(with: sessionUuid)
        handler.resumeBillingSession(with: sessionUuid)

        billingService.assertEvents([
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive),
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive),
            .resumeBillingSession(.freeDrive),
        ])
    }

    func testForceStartNewBillingSessionOnPausedSessionWithOneActive() {
        let sessionUuid = UUID()
        let sessionUuid2 = UUID()
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid)
        handler.beginBillingSession(for: .activeGuidance, uuid: sessionUuid2)
        handler.pauseBillingSession(with: sessionUuid)
        handler.beginNewBillingSessionIfExists(with: sessionUuid)
        handler.resumeBillingSession(with: sessionUuid)

        billingService.assertEvents([
            .beginBillingSession(.activeGuidance),
            .beginBillingSession(.activeGuidance),
        ])
    }

    func testTripPerWaypoint() {
        let waypointCoordinates = [
            CLLocationCoordinate2D(latitude: 37.751748, longitude: -122.387589),
            CLLocationCoordinate2D(latitude: 37.752397, longitude: -122.387631),
            CLLocationCoordinate2D(latitude: 37.753186, longitude: -122.387721),
            CLLocationCoordinate2D(latitude: 37.75405, longitude: -122.38781),
            CLLocationCoordinate2D(latitude: 37.754817, longitude: -122.387859),
            CLLocationCoordinate2D(latitude: 37.755594, longitude: -122.38793),
            CLLocationCoordinate2D(latitude: 37.756574, longitude: -122.388057),
            CLLocationCoordinate2D(latitude: 37.757531, longitude: -122.388198),
            CLLocationCoordinate2D(latitude: 37.758628, longitude: -122.388322),
            CLLocationCoordinate2D(latitude: 37.759682, longitude: -122.388401),
            CLLocationCoordinate2D(latitude: 37.760872, longitude: -122.388511),
        ]

        let waypoints = waypointCoordinates.map({ Waypoint(coordinate: $0) })

        var routeOptions: NavigationRouteOptions {


            return NavigationRouteOptions(waypoints: waypoints)
        }
        
        let route = Fixture.route(from: "route-with-10-legs", options: routeOptions)
        
        autoreleasepool {
            let replayLocations = Fixture.generateTrace(for: route).shiftedToPresent()
            let routeResponse = IndexedRouteResponse(routeResponse: RouteResponse(httpResponse: nil,
                                                                                  routes: [route],
                                                                                  options: .route(.init(coordinates: waypointCoordinates)),
                                                                                  credentials: .mocked),
                                                     routeIndex: 0)

            let routeController = RouteController(indexedRouteResponse: routeResponse,
                                                  customRoutingProvider: MapboxRoutingProvider(.offline),
                                                  dataSource: self)

            let routerDelegateSpy = RouterDelegateSpy()
            routeController.delegate = routerDelegateSpy

            let locationManager = ReplayLocationManager(locations: replayLocations)
            locationManager.delegate = routeController

            let arrivedAtWaypoint = expectation(description: "Arrive at waypoint")
            arrivedAtWaypoint.expectedFulfillmentCount = route.legs.count
            routerDelegateSpy.onDidArriveAt = { waypoint in
                arrivedAtWaypoint.fulfill()
                return true
            }

            locationManager.speedMultiplier = 10
            locationManager.startUpdatingLocation()
            waitForExpectations(timeout: locationManager.expectedReplayTime, handler: nil)
            locationManager.stopUpdatingLocation()
        }

        var expectedEvents: [BillingServiceMock.Event] = []
        for _ in 0..<route.legs.count {
            expectedEvents.append(.beginBillingSession(.activeGuidance))
        }
        expectedEvents.append(.stopBillingSession(.activeGuidance))
        billingServiceMock.assertEvents(expectedEvents)
    }

    func testPausedFreeDrivePausesNavNativeNavigator() {
        let locationManager = ReplayLocationManager(locations: [.init(coordinate: .init(latitude: 0, longitude: 0))])
        locationManager.speedMultiplier = 100
        locationManager.replayCompletionHandler = { _ in true }

        let passiveLocationManager = PassiveLocationManager(directions: .mocked,
                                                            systemLocationManager: locationManager)
        let updatesSpy = PassiveLocationManagerDelegateSpy()
        passiveLocationManager.delegate = updatesSpy
        let progressWorks = expectation(description: "Progress Works")
        progressWorks.assertForOverFulfill = false
        updatesSpy.onProgressUpdate = { _,_ in
            progressWorks.fulfill()
        }

        passiveLocationManager.startUpdatingLocation()
        wait(for: [progressWorks], timeout: 2)

        passiveLocationManager.pauseTripSession()

        billingServiceMock.assertEvents([
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive)
        ])

        var updatesAfterPauseCount: Int = 0

        updatesSpy.onProgressUpdate = { _,_ in
            updatesAfterPauseCount += 1
        }

        // Give NavNative a reasonable amount of time (a second) to allow sending progress updates after pause.
        RunLoop.main.run(until: Date().addingTimeInterval(1))

        let statusChangeSubscription = NotificationCenter.default.addObserver(forName: .navigationStatusDidChange,
                                                                              object: nil,
                                                                              queue: .main) { _ in
            updatesAfterPauseCount += 1
        }

        withExtendedLifetime(statusChangeSubscription) { statusChangeSubscription in
            // Force updates directly to MapboxNavigationNative.Navigator to check that this navigator is paused as well.
            func forceSendNextLocation(idx: Int) {
                guard let lastLocation = locationManager.location else {
                    XCTFail("Unexpected nil location in ReplayLocationManager"); return
                }
                let nextLocation = lastLocation.shifted(to: lastLocation.timestamp.addingTimeInterval(TimeInterval(idx)))
                Navigator.shared.navigator.updateLocation(for: FixLocation(nextLocation)) { success in
                    XCTAssertFalse(success) // For paused Navigator updateLocation MUST return false
                }
            }
            forceSendNextLocation(idx: 1)
            DispatchQueue.main.async {
                forceSendNextLocation(idx: 2)
            }
            RunLoop.main.run(until: Date().addingTimeInterval(3))

            // We expect at most one status update after
            XCTAssertLessThanOrEqual(updatesAfterPauseCount, 1)

            NotificationCenter.default.removeObserver(statusChangeSubscription)
        }
    }

    func testStressTest() {
        let finished = expectation(description: "Finished")
        DispatchQueue.global().async {
            DispatchQueue.concurrentPerform(iterations: 1000) { iterationIdx in
                let sessionUuid = UUID()
                let sessionType = BillingHandler.SessionType.random()
                self.handler.beginBillingSession(for: sessionType, uuid: sessionUuid)
                self.handler.pauseBillingSession(with: sessionUuid)
                self.handler.beginNewBillingSessionIfExists(with: sessionUuid)
                self.handler.resumeBillingSession(with: sessionUuid)
                self.handler.stopBillingSession(with: sessionUuid)
            }
            finished.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}

extension BillingHandlerTests: RouterDataSource {
    var locationManagerType: NavigationLocationManager.Type {
        return NavigationLocationManager.self
    }
}

private extension BillingHandler.SessionType {
    static func random() -> Self {
        if (0..<1).randomElement()! == 0 {
            return .freeDrive
        }
        else {
            return .activeGuidance
        }
    }
}
