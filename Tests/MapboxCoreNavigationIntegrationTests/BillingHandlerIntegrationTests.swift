import Foundation
import XCTest
import CoreLocation
import TestHelper
import MapboxNavigationNative
import MapboxDirections
@testable import MapboxCoreNavigation

final class BillingHandlerIntegrationTests: TestCase {
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
        billingService = nil
        handler = nil
        navigator = nil
        
        super.tearDown()
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
}

extension BillingHandlerIntegrationTests: RouterDataSource {
    var locationManagerType: NavigationLocationManager.Type {
        return NavigationLocationManager.self
    }
}
