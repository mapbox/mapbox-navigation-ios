@testable import _MapboxNavigationTestHelpers
import Combine
import CoreLocation
import MapboxDirections
@_spi(MapboxInternal) @testable import MapboxNavigationCore
import MapboxNavigationNative_Private
import XCTest

final class MapboxNavigatorTests: TestCase {
    var navigator: MapboxNavigator!
    var coreNavigator: CoreNavigatorMock!
    var subscriptions: Set<AnyCancellable>!
    var refreshNotification: Notification!
    var routeRefreshResult: RouteRefreshResult!
    let timeout: TimeInterval = 0.5
    var locationClientState: MockLocationClientState!
    var routeProgress: RouteProgress!

    var routeProgressUpdateExpectation: XCTestExpectation?

    override func setUp() async throws {
        try? await super.setUp()

        subscriptions = []
        locationClientState = MockLocationClientState()
        coreNavigator = await CoreNavigatorMock()
        coreNavigator.setRoutesResult = .success((RouteInfo(alerts: []), []))
        routeRefreshResult = RouteRefreshResult.mainRoute(RouteInterfaceMock())
        let legIndex = UInt32(0)
        let userInfo: [AnyHashable: Any] = [
            NativeNavigator.NotificationUserInfoKey.refreshedRoutesResultKey: routeRefreshResult!,
            NativeNavigator.NotificationUserInfoKey.legIndexKey: legIndex,
        ]
        refreshNotification = Notification(name: .routeRefreshDidUpdateAnnotations, userInfo: userInfo)
        routeProgress = await .mock()
        let coonfiguration = MapboxNavigator.Configuration(
            navigator: coreNavigator,
            routeParserType: RouteParser.self,
            locationClient: .mockLocationClient(
                locationPublisher: locationPublisher.eraseToAnyPublisher(),
                state: locationClientState
            ),
            alternativesAcceptionPolicy: coreConfig.routingConfig.alternativeRoutesDetectionConfig?
                .acceptionPolicy,
            billingHandler: coreConfig.__customBillingHandler!(),
            multilegAdvancing: coreConfig.multilegAdvancing,
            prefersOnlineRoute: coreConfig.routingConfig.prefersOnlineRoute,
            disableBackgroundTrackingLocation: coreConfig.disableBackgroundTrackingLocation,
            fasterRouteController: nil,
            electronicHorizonConfig: nil,
            congestionConfig: .default,
            movementMonitor: .init()
        )
        navigator = await MapboxNavigator(configuration: coonfiguration)

        navigator.routeProgress
            .compactMap { $0 }
            .sink(receiveValue: { [weak self] _ in
                self?.routeProgressUpdateExpectation?.fulfill()
            })
            .store(in: &subscriptions)
    }

    override func tearDown() async throws {
        subscriptions = []
        await navigator.setToIdle()
        Environment.switchEnvironment(to: .live)
        try await super.tearDown()
    }

    var rerouteController: RerouteController {
        coreNavigator.rerouteController!
    }

    @MainActor
    func testStartActiveGuidanceAndRefresh() async {
        XCTAssertFalse(navigator.currentSession.state.isTripSessionActive)

        let navigationRoutes = await NavigationRoutes.mock()
        navigator.privateSession.emit(Session(state: .activeGuidance(.initialized)))

        for _ in 0..<100 {
            navigator.startActiveGuidance(with: navigationRoutes, startLegIndex: 0)
            navigator.setRoutes(
                navigationRoutes: navigationRoutes,
                startLegIndex: 0,
                reason: .newRoute,
                previousRouteProgress: routeProgress
            )
            navigator.didRefreshAnnotations(refreshNotification)
        }
        XCTAssertTrue(navigator.currentSession.state.isTripSessionActive)
    }

    @MainActor
    func testStartActiveGuidanceAndFreeDrive() async {
        let navigationRoutes = await NavigationRoutes.mock()

        for _ in 0..<100 {
            navigator.startActiveGuidance(with: navigationRoutes, startLegIndex: 0)
            navigator.startFreeDrive()
        }
    }

    @MainActor
    func testMultipleUpdatesSetRouteTask() async {
        XCTAssertFalse(navigator.currentSession.state.isTripSessionActive)

        let navigationRoutes = await NavigationRoutes.mock()
        navigator.startActiveGuidance(with: navigationRoutes, startLegIndex: 0)
        navigator.privateSession.emit(Session(state: .activeGuidance(.initialized)))

        let status = NavigationStatus.mock()
        let userInfo: [AnyHashable: Any] = [
            NativeNavigator.NotificationUserInfoKey.statusKey: status,
        ]
        let statusNotification = Notification(name: .navigationStatusDidChange, userInfo: userInfo)

        for _ in 0..<100 {
            Task.detached { [weak self] in
                guard let self else { return }
                NotificationCenter.default.post(statusNotification)
                await navigator.setRoutes(
                    navigationRoutes: navigationRoutes,
                    startLegIndex: 0,
                    reason: .newRoute,
                    previousRouteProgress: routeProgress
                )
            }
        }
        XCTAssertTrue(navigator.currentSession.state.isTripSessionActive)
    }

    @MainActor
    func testUpdateNavigationRoutesFromStatus() async {
        let navigationRoutes = await NavigationRoutes.mock()
        await startActiveGuidanceAndWaitForState(with: navigationRoutes)

        let status = NavigationStatus.mock()
        let userInfo: [AnyHashable: Any] = [
            NativeNavigator.NotificationUserInfoKey.statusKey: status,
        ]
        let statusNotification = Notification(name: .navigationStatusDidChange, userInfo: userInfo)

        for _ in 0..<100 {
            Task.detached { [weak self] in
                guard let self else { return }
                NotificationCenter.default.post(statusNotification)
                navigator.didRefreshAnnotations(refreshNotification)
                await navigator.setRoutes(
                    navigationRoutes: navigationRoutes,
                    startLegIndex: 0,
                    reason: .reroute(.deviation),
                    previousRouteProgress: routeProgress
                )
            }
        }
        XCTAssertTrue(navigator.currentSession.state.isTripSessionActive)
    }

    func testUpdateMapMatchingResult() async {
        let enhancedLocation = CLLocation(latitude: 1.0, longitude: 2.0)
        let rawLocation = CLLocation(latitude: 3.0, longitude: 4.0)
        coreNavigator.rawLocation.update(rawLocation)
        let status = NavigationStatus.mock(
            location: enhancedLocation,
            offRoadProba: 0.5
        )

        let expectation = expectation(description: "Publisher")
        await navigator.locationMatching.sink { state in
            XCTAssertEqual(state.enhancedLocation.coordinate, enhancedLocation.coordinate)
            // TODO: investigate why we need 0 when in v2 we used to have -1 for undefined speed
            XCTAssertEqual(state.enhancedLocation.speed, 0)
            XCTAssertEqual(state.location, rawLocation)
            XCTAssertFalse(state.mapMatchingResult.isOffRoad)
            XCTAssertEqual(state.mapMatchingResult.offRoadProbability, 0.5)
            expectation.fulfill()
        }.store(in: &subscriptions)

        await navigator.updateMapMatching(status: status)
        await fulfillment(of: [expectation], timeout: timeout)
    }

    func testUpdateSpeedLimitIfMilesPerHour() async {
        let status = NavigationStatus.mock(
            speedLimit: .init(
                speed: 50,
                localeUnit: .milesPerHour,
                localeSign: .mutcd
            )
        )
        let expectation = expectation(description: "Publisher")

        let expectedSpeedLimit = SpeedLimit(value: .init(value: 50, unit: .milesPerHour), signStandard: .mutcd)
        await navigator.locationMatching.sink { state in
            XCTAssertEqual(state.speedLimit, expectedSpeedLimit)
            expectation.fulfill()
        }.store(in: &subscriptions)

        await navigator.updateMapMatching(status: status)
        await fulfillment(of: [expectation], timeout: timeout)
    }

    func testUpdateSpeedLimitIfKilometersPerHour() async {
        let status = NavigationStatus.mock(
            speedLimit: .init(
                speed: 100,
                localeUnit: .kilometresPerHour,
                localeSign: .vienna
            )
        )
        let expectation = expectation(description: "Publisher")

        let expectedSpeed = Measurement<UnitSpeed>(value: 100, unit: .kilometersPerHour)
        let expectedSpeedLimit = SpeedLimit(value: expectedSpeed, signStandard: .viennaConvention)
        await navigator.locationMatching.sink { state in
            XCTAssertEqual(state.speedLimit, expectedSpeedLimit)
            expectation.fulfill()
        }.store(in: &subscriptions)

        await navigator.updateMapMatching(status: status)
        await fulfillment(of: [expectation], timeout: timeout)
    }

    func testUpdateCurrentSpeedIfMilesPerHour() async {
        let date = "2024-01-01T15:00:00.000Z".ISO8601Date!
        let location1 = CLLocation(
            coordinate: .init(latitude: 1, longitude: 2),
            altitude: -1,
            horizontalAccuracy: -1,
            verticalAccuracy: -1,
            course: -1,
            speed: 13,
            timestamp: date
        )
        let status = NavigationStatus.mock(
            location: location1,
            speedLimit: .init(
                speed: 50,
                localeUnit: .milesPerHour,
                localeSign: .mutcd
            )
        )
        let expectation = expectation(description: "Publisher")

        let expectedSpeed = Measurement<UnitSpeed>(value: 13, unit: .metersPerSecond).converted(to: .milesPerHour)
        await navigator.locationMatching.sink { state in
            XCTAssertEqual(state.currentSpeed, expectedSpeed)
            expectation.fulfill()
        }.store(in: &subscriptions)

        await navigator.updateMapMatching(status: status)
        await fulfillment(of: [expectation], timeout: timeout)
    }

    func testUpdateCurrentSpeedIfKilometersPerHour() async {
        let date = "2024-01-01T15:00:00.000Z".ISO8601Date!
        let location1 = CLLocation(
            coordinate: .init(latitude: 1, longitude: 2),
            altitude: -1,
            horizontalAccuracy: -1,
            verticalAccuracy: -1,
            course: -1,
            speed: 13,
            timestamp: date
        )
        let status = NavigationStatus.mock(
            location: location1,
            speedLimit: .init(
                speed: 100,
                localeUnit: .kilometresPerHour,
                localeSign: .mutcd
            )
        )
        let expectation = expectation(description: "Publisher")

        let expectedSpeed = Measurement<UnitSpeed>(value: 13, unit: .metersPerSecond).converted(to: .kilometersPerHour)
        await navigator.locationMatching.sink { state in
            XCTAssertEqual(state.currentSpeed, expectedSpeed)
            expectation.fulfill()
        }.store(in: &subscriptions)

        await navigator.updateMapMatching(status: status)
        await fulfillment(of: [expectation], timeout: timeout)
    }

    func testUpdateMapMatchingStateLocationRoadName() async {
        let status = NavigationStatus.mock(
            roads: [.init(text: "Name", language: "", imageBaseUrl: "image_url", shield: nil)]
        )
        let expectation = expectation(description: "Publisher")

        await navigator.locationMatching.sink { state in
            XCTAssertEqual(state.roadName, .init(text: "Name", language: ""))
            expectation.fulfill()
        }.store(in: &subscriptions)

        await navigator.updateMapMatching(status: status)
        await fulfillment(of: [expectation], timeout: timeout)
    }

    @MainActor
    func testSetStateToIdleAsyncAfterFreeDrive() async {
        await startFreeDriveAndWaitForState()
        await setToIdleAndWaitForState()

        let state = navigator.currentSession.state
        XCTAssertEqual(state, .idle)
        XCTAssertTrue(coreNavigator.pauseCalled)
        XCTAssertFalse(coreNavigator.unsetRoutesCalled)
        XCTAssertFalse(locationClientState.updatingHeading)
        XCTAssertFalse(locationClientState.updatingLocation)
        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .activeGuidance), .stopped)
        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .freeDrive), .paused)
    }

    @MainActor
    func testSetStateToIdleAsyncAfterActiveGuidance() async {
        routeProgressUpdateExpectation = XCTestExpectation(description: "navigator callback startActiveGuidance")
        await startActiveGuidanceAndWaitForState(with: .mock())
        await fulfillment(of: [routeProgressUpdateExpectation!], timeout: timeout)

        await setToIdleAndWaitForState()
        let state = navigator.currentSession.state
        XCTAssertEqual(state, .idle)
        XCTAssertTrue(coreNavigator.pauseCalled)
        XCTAssertTrue(coreNavigator.unsetRoutesCalled)
        XCTAssertFalse(locationClientState.updatingHeading)
        XCTAssertFalse(locationClientState.updatingLocation)
        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .activeGuidance), .paused)
        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .freeDrive), .stopped)
    }

    @MainActor
    func testStartActiveGuidance() async {
        routeProgressUpdateExpectation = XCTestExpectation(description: "navigator callback startActiveGuidance")
        let activeGuidanceExpectation = trackingStatusExpectation(state: .activeGuidance(.uncertain))
        await navigator.startActiveGuidance(with: .mock(), startLegIndex: 0)

        XCTAssertEqual(navigator.currentSession.state, .idle)
        XCTAssertFalse(coreNavigator.unsetRoutesCalled)
        XCTAssertTrue(coreNavigator.setRoutesCalled)
        XCTAssertTrue(locationClientState.updatingHeading)
        XCTAssertTrue(locationClientState.updatingLocation)
        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .activeGuidance), .running)
        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .freeDrive), .stopped)
        billingServiceMock.assertEvents([
            .beginBillingSession(.activeGuidance),
        ])
        await fulfillment(of: [activeGuidanceExpectation, routeProgressUpdateExpectation!], timeout: timeout)
        XCTAssertEqual(navigator.currentSession.state, .activeGuidance(.uncertain))
    }

    @MainActor
    func testSetStateToFreeDrive() async {
        await startFreeDriveAndWaitForState()
        XCTAssertEqual(navigator.currentSession.state, .freeDrive(.active))
        XCTAssertTrue(locationClientState.updatingHeading)
        XCTAssertTrue(locationClientState.updatingLocation)
        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .freeDrive), .running)
    }

    func testPauseAndResumeActiveGuidanceSession() async {
        await startActiveGuidanceAndWaitForState(with: .mock())
        await setToIdleAndWaitForState()
        await startActiveGuidanceAndWaitForState(with: .mock())

        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .activeGuidance), .running)
        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .freeDrive), .stopped)
        billingServiceMock.assertEvents([
            .beginBillingSession(.activeGuidance),
            .pauseBillingSession(.activeGuidance),
            .resumeBillingSession(.activeGuidance),
        ])
    }

    func testPauseAndResumeActiveMultiwaypointGuidanceSession() async {
        let mainRoute = Route.mock(legs: [.mock(), .mock(), .mock()])
        let navigationRoute = NavigationRoute.mock(route: mainRoute)
        let routes = await NavigationRoutes.mock(mainRoute: navigationRoute)

        await startActiveGuidanceAndWaitForState(with: routes, startLegIndex: 1)
        await setToIdleAndWaitForState()
        await startActiveGuidanceAndWaitForState(with: routes, startLegIndex: 1)

        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .activeGuidance), .running)
        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .freeDrive), .stopped)
        billingServiceMock.assertEvents([
            .beginBillingSession(.activeGuidance),
            .pauseBillingSession(.activeGuidance),
            .resumeBillingSession(.activeGuidance),
        ])
    }

    func testStartNewBillingSessionWithMultiwaypointRouteAndDifferentLeg() async {
        let mainRoute = Route.mock(legs: [.mock(), .mock(), .mock()])
        let navigationRoute = NavigationRoute.mock(route: mainRoute)
        let routes = await NavigationRoutes.mock(mainRoute: navigationRoute)

        await startActiveGuidanceAndWaitForState(with: routes, startLegIndex: 1)
        await setToIdleAndWaitForState()
        await startActiveGuidanceAndWaitForState(with: routes, startLegIndex: 2)

        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .activeGuidance), .running)
        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .freeDrive), .stopped)
        billingServiceMock.assertEvents([
            .beginBillingSession(.activeGuidance),
            .pauseBillingSession(.activeGuidance),
            .stopBillingSession(.activeGuidance),
            .beginBillingSession(.activeGuidance),
        ])
    }

    @MainActor
    func testPauseAndStartActiveGuidanceSessionWhenFreeDrive() async {
        await startActiveGuidanceAndWaitForState(with: .mock(), startLegIndex: 0)
        await setToIdleAndWaitForState()
        await startFreeDriveAndWaitForState()
        await startActiveGuidanceAndWaitForState(with: .mock(), startLegIndex: 0)

        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .activeGuidance), .running)
        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .freeDrive), .stopped)
        billingServiceMock.assertEvents([
            .beginBillingSession(.activeGuidance),
            .pauseBillingSession(.activeGuidance),
            .stopBillingSession(.activeGuidance),
            .beginBillingSession(.freeDrive),
            .stopBillingSession(.freeDrive),
            .beginBillingSession(.activeGuidance),
        ])
    }

    func testPauseAndStartNewSessionIfShouldStartNewSesion() async {
        await startActiveGuidanceAndWaitForState(with: .mock(), startLegIndex: 0)
        await setToIdleAndWaitForState()
        var leg = RouteLeg.mock()
        leg.destination = Waypoint(coordinate: .init(latitude: 1.5, longitude: 2.5))
        let routes = await NavigationRoutes.mock(
            mainRoute: .mock(route: .mock(legs: [leg]))
        )
        await startActiveGuidanceAndWaitForState(with: routes, startLegIndex: 0)

        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .activeGuidance), .running)
        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .freeDrive), .stopped)
        billingServiceMock.assertEvents([
            .beginBillingSession(.activeGuidance),
            .pauseBillingSession(.activeGuidance),
            .stopBillingSession(.activeGuidance),
            .beginBillingSession(.activeGuidance),
        ])
    }

    func testPauseAndResumeSessionIfDistanceBetweenDestinationsLess100Meters() async {
        await startActiveGuidanceAndWaitForState(with: .mock(), startLegIndex: 0)
        await setToIdleAndWaitForState()
        var leg = RouteLeg.mock()
        leg.destination = Waypoint(coordinate: .init(latitude: 1.0005, longitude: 2.0005))
        let routes = await NavigationRoutes.mock(
            mainRoute: .mock(route: .mock(legs: [leg]))
        )
        await startActiveGuidanceAndWaitForState(with: routes, startLegIndex: 0)

        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .activeGuidance), .running)
        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .freeDrive), .stopped)
        billingServiceMock.assertEvents([
            .beginBillingSession(.activeGuidance),
            .pauseBillingSession(.activeGuidance),
            .resumeBillingSession(.activeGuidance),
        ])
    }

    @MainActor
    func testSetRoutesSimilarNewRouteKeepsSession() async {
        await startActiveGuidanceAndWaitForState(with: oneLegNavigationRoutes())
        await setRoutes(with: oneLegNavigationRoutes(), reason: .newRoute)

        billingServiceMock.assertEvents([.beginBillingSession(.activeGuidance)])
    }

    @MainActor
    func testSetRoutesSimilarRerouteKeepsSession() async {
        await startActiveGuidanceAndWaitForState(with: oneLegNavigationRoutes())
        await setRoutes(with: oneLegNavigationRoutes(), reason: .reroute(.deviation))

        billingServiceMock.assertEvents([.beginBillingSession(.activeGuidance)])
    }

    @MainActor
    func testSetRoutesDifferentNewRouteBeginsNewSession() async {
        await startActiveGuidanceAndWaitForState(with: twoLegNavigationRoutes())
        await setRoutes(with: oneLegNavigationRoutes(), reason: .newRoute)

        billingServiceMock.assertEvents([
            .beginBillingSession(.activeGuidance),
            .stopBillingSession(.activeGuidance),
            .beginBillingSession(.activeGuidance),
        ])
    }

    @MainActor
    func testSetRoutesDifferentRerouteBeginsNewSession() async {
        await startActiveGuidanceAndWaitForState(with: twoLegNavigationRoutes())
        await setRoutes(with: oneLegNavigationRoutes(), reason: .reroute(.deviation))

        billingServiceMock.assertEvents([
            .beginBillingSession(.activeGuidance),
            .stopBillingSession(.activeGuidance),
            .beginBillingSession(.activeGuidance),
        ])
    }

    @MainActor
    func testSetRoutesMapMatchingRerouteToDirectionsWithSameDestinationKeepsSession() async {
        // This scenario happens with RerouteStrategyForMatchRoute.navigateToFinalDestination
        // when there were more than one waypoint remaining before reroute
        await startActiveGuidanceAndWaitForState(with: twoLegNavigationRoutes(mapboxApi: .mapMatching))
        let reason = MapboxNavigator.SetRouteReason.reroute(.deviation)
        await setRoutes(with: oneLegNavigationRoutes(mapboxApi: .directions), reason: reason)

        billingServiceMock.assertEvents([.beginBillingSession(.activeGuidance)])
    }

    func testRefreshMainRoute() async {
        let originalRoutes = await NavigationRoutes.mock(
            mainRoute: .mock(),
            alternativeRoutes: [.mock()]
        )
        mockAlternativesRoutesDataParser()
        await startActiveGuidanceAndWaitForState(with: originalRoutes, startLegIndex: 0)

        let refreshedDirectionsRoute = Route.mock(legs: [refreshedLeg])
        let refreshedRoute = RouteInterfaceMock(
            route: refreshedDirectionsRoute,
            routeId: originalRoutes.mainRoute.nativeRouteInterface.getRouteId()
        )
        let routeRefreshResult = RouteRefreshResult.mainRoute(refreshedRoute)
        let notification = makeRefreshNotification(routeRefreshResult: routeRefreshResult)

        await refresh(with: notification)

        let currentProgress = await navigator.currentRouteProgress!.routeProgress
        XCTAssertEqual(currentProgress.currentLegProgress.leg, refreshedDirectionsRoute.legs[0])
        let currentRoutes = currentProgress.navigationRoutes
        XCTAssertEqual(currentRoutes.mainRoute.route.legs, refreshedDirectionsRoute.legs)
        XCTAssertEqual(currentRoutes.alternativeRoutes[0].route.legs, originalRoutes.alternativeRoutes[0].route.legs)
    }

    func testRefreshAlternativeRoute() async {
        let originalRoutes = await NavigationRoutes.mock(
            mainRoute: .mock(),
            alternativeRoutes: [.mock()]
        )
        mockAlternativesRoutesDataParser()
        await navigator.startActiveGuidance(with: originalRoutes, startLegIndex: 0)
        await waitForRouteProgressUpdate()

        let refreshedDirectionsRoute = Route.mock(legs: [refreshedLeg])
        let refreshedRoute = RouteInterfaceMock(
            route: refreshedDirectionsRoute,
            routeId: originalRoutes.alternativeRoutes[0].nativeRoute.getRouteId()
        )
        let refreshedAlternative = RouteAlternative.mock(route: refreshedRoute)
        let routeRefreshResult = RouteRefreshResult.alternativeRoute(alternative: refreshedAlternative)
        let notification = makeRefreshNotification(routeRefreshResult: routeRefreshResult)

        await refresh(with: notification)

        let currentProgress = await navigator.currentRouteProgress!.routeProgress
        XCTAssertEqual(currentProgress.currentLegProgress.leg, originalRoutes.mainRoute.route.legs[0])
        let currentRoutes = currentProgress.navigationRoutes
        XCTAssertEqual(currentRoutes.mainRoute, originalRoutes.mainRoute)
        XCTAssertEqual(currentRoutes.alternativeRoutes[0].route.legs, refreshedDirectionsRoute.legs)
    }

    func testRefreshMultilegRoute() async {
        let stepsFor1Leg: [RouteStep] = [
            .mock(maneuverType: .depart),
            .mock(maneuverType: .arrive),
        ]
        let originalMainRoute = Route.mock(legs: [.mock(steps: stepsFor1Leg), .mock()])
        let originalRoutes = await NavigationRoutes.mock(
            mainRoute: .mock(route: originalMainRoute),
            alternativeRoutes: [.mock()]
        )
        mockAlternativesRoutesDataParser()
        await navigator.startActiveGuidance(with: originalRoutes, startLegIndex: 1)
        await waitForRouteProgressUpdate()
        Environment.switchEnvironment(to: .live)

        let refreshedDirectionsRoute = Route.mock(legs: [refreshedLeg])
        let refreshedRoute = RouteInterfaceMock(
            route: refreshedDirectionsRoute,
            routeId: originalRoutes.alternativeRoutes[0].nativeRoute.getRouteId()
        )
        let refreshedAlternative = RouteAlternative.mock(route: refreshedRoute)
        let routeRefreshResult = RouteRefreshResult.alternativeRoute(alternative: refreshedAlternative)
        let notification = makeRefreshNotification(routeRefreshResult: routeRefreshResult, legIndex: 0)

        await refresh(with: notification)

        let currentProgress = await navigator.currentRouteProgress!.routeProgress
        XCTAssertEqual(currentProgress.currentLegProgress.leg, originalRoutes.mainRoute.route.legs[1])
        let currentRoutes = currentProgress.navigationRoutes
        XCTAssertEqual(currentRoutes.mainRoute, originalRoutes.mainRoute)
        XCTAssertEqual(currentRoutes.alternativeRoutes[0].route.legs, refreshedDirectionsRoute.legs)
    }

    @MainActor
    func testSendSessionEventsWithoutDuplication() async {
        var resultSession: Session = .init(state: .freeDrive(.paused))
        var eventsCounter = 0
        var cancellables = Set<AnyCancellable>()

        navigator.session
            .sink { session in
                resultSession = session
                eventsCounter += 1
            }
            .store(in: &cancellables)

        XCTAssertEqual(resultSession, .init(state: .idle)) // initial navigator state
        XCTAssertEqual(eventsCounter, 1)

        navigator.startFreeDrive() // this method always sends .freeDrive(.active)
        navigator.startFreeDrive()
        navigator.startFreeDrive()

        XCTAssertEqual(resultSession, .init(state: .freeDrive(.active)))
        XCTAssertEqual(eventsCounter, 2)
    }

    @MainActor
    func testSendBannerInstructionWithoutDuplication() async {
        let bannerInstruction1 = VisualInstructionBanner.mock(primaryInstructionText: "first")
        let bannerInstruction2 = VisualInstructionBanner.mock(primaryInstructionText: "second")
        let bannerInstructions = [bannerInstruction1, bannerInstruction2]

        var eventsCounter = 0
        var cancellables = Set<AnyCancellable>()

        navigator.bannerInstructions
            .sink { instruction in
                XCTAssertEqual(instruction.visualInstruction, bannerInstructions[eventsCounter])
                eventsCounter += 1
            }
            .store(in: &cancellables)

        XCTAssertEqual(eventsCounter, 0)

        let step = RouteStep.mock(instructionsDisplayedAlongStep: bannerInstructions)
        let route = Route.mock(legs: [.mock(steps: [step, .mock(maneuverType: .arrive)])])
        var routeProgress = await RouteProgress.mock(
            navigationRoutes: .mock(mainRoute: .mock(route: route))
        )
        var status = NavigationStatus.mock()

        await navigator.handleRouteProgressUpdates(status: status, routeProgress: routeProgress)
        XCTAssertEqual(eventsCounter, 1)

        await navigator.handleRouteProgressUpdates(status: status, routeProgress: routeProgress)
        XCTAssertEqual(eventsCounter, 1)

        status = .mock(bannerInstruction: .mock(index: 1))
        routeProgress.update(using: status)
        await navigator.handleRouteProgressUpdates(status: status, routeProgress: routeProgress)

        XCTAssertEqual(eventsCounter, 2)

        status = .mock(stepIndex: 1, bannerInstruction: .mock(index: 0))
        routeProgress.update(using: status)
        await navigator.handleRouteProgressUpdates(status: status, routeProgress: routeProgress)

        XCTAssertEqual(eventsCounter, 2, "Don't send an update if no new banner instruction")
    }

    func testRerouteControllerWantsSwitchToAlternativeIfDefaultOptions() async {
        await startActiveGuidanceAndWaitForRouteProgressUpdate(with: oneLegNavigationRoutes())
        let route = RouteInterfaceMock()
        navigator.rerouteControllerWantsSwitchToAlternative(rerouteController, route: route, legIndex: 0)
        await waitForRouteProgressUpdate()

        XCTAssertTrue(coreNavigator.setRoutesCalled)
        XCTAssertEqual(coreNavigator.passedSetReason, .alternative)

        let currentRoutes = navigator.currentNavigationRoutes!
        let expectedOptions = route.getResponseOptions(NavigationRouteOptions.self)!
        XCTAssertEqual(currentRoutes.mainRoute.nativeRouteInterface.getRouteId(), route.getRouteId())
        XCTAssertEqual(currentRoutes.mainRoute.requestOptions, expectedOptions)
    }

    func testRerouteControllerWantsSwitchToAlternativeIfCustomOptions() async {
        let initialRoutes = await oneLegNavigationRoutes(directionsOptionsType: GolfCartRouteOptions.self)
        await startActiveGuidanceAndWaitForRouteProgressUpdate(with: initialRoutes)
        let route = RouteInterfaceMock()
        navigator.rerouteControllerWantsSwitchToAlternative(rerouteController, route: route, legIndex: 0)
        await waitForRouteProgressUpdate()

        XCTAssertTrue(coreNavigator.setRoutesCalled)
        XCTAssertEqual(coreNavigator.passedSetReason, .alternative)

        let currentRoutes = navigator.currentNavigationRoutes!
        XCTAssertEqual(currentRoutes.mainRoute.nativeRouteInterface.getRouteId(), route.getRouteId())
        XCTAssertTrue(type(of: currentRoutes.mainRoute.directionOptions) == GolfCartRouteOptions.self)
    }

    @MainActor
    func testRouteProgressEventsOnStartActiveGuidance() async {
        let routes = await oneLegNavigationRoutes()
        let expectation = setupRouteProgressExpectation(for: routes.mainRoute.route)

        await startActiveGuidanceAndWaitForRouteProgressUpdate(with: routes)
        let progress = navigator.currentRouteProgress?.routeProgress
        XCTAssertEqual(progress?.navigationRoutes, routes)
        await fulfillment(of: [expectation], timeout: timeout)
    }

    @MainActor
    func testStartActiveGuidanceIfValidNNStatus() async {
        let navigationRoutes = await twoLegNavigationRoutes()
        let nativeRoute = navigationRoutes.mainRoute.nativeRouteInterface
        let routeId = nativeRoute.getRouteId()

        coreNavigator.returnedNavigationStatus = { _, _ in
            .mock(
                primaryRouteId: nativeRoute.getResponseUuid(),
                legIndex: 1,
                stepIndex: 3
            )
        }

        navigator.startActiveGuidance(with: navigationRoutes, startLegIndex: 1)
        await waitForRouteProgressUpdate()
        let progress = navigator.currentRouteProgress?.routeProgress
        XCTAssertEqual(progress?.legIndex, 1)
        XCTAssertEqual(progress?.routeId.rawValue, routeId)
        XCTAssertEqual(progress?.currentLegProgress.stepIndex, 3)
    }

    @MainActor
    func testStartActiveGuidanceIfInvalidNNStatus() async {
        let navigationRoutes = await twoLegNavigationRoutes()
        let nativeRoute = navigationRoutes.mainRoute.nativeRouteInterface
        let routeId = nativeRoute.getRouteId()

        coreNavigator.returnedNavigationStatus = { _, _ in
            .mock(
                primaryRouteId: nativeRoute.getResponseUuid(),
                legIndex: 0, // different legIndex
                stepIndex: 3
            )
        }
        navigator.startActiveGuidance(with: navigationRoutes, startLegIndex: 1)
        await waitForRouteProgressUpdate()
        let progress = navigator.currentRouteProgress?.routeProgress
        XCTAssertEqual(progress?.legIndex, 1)
        XCTAssertEqual(progress?.routeId.rawValue, routeId)
        XCTAssertEqual(progress?.currentLegProgress.stepIndex, 0)

        coreNavigator.returnedNavigationStatus = { _, _ in
            .mock(
                primaryRouteId: "incorrect", // different primaryRouteId
                legIndex: 1,
                stepIndex: 3
            )
        }
        navigator.startActiveGuidance(with: navigationRoutes, startLegIndex: 1)
        await waitForRouteProgressUpdate()
        let progress2 = navigator.currentRouteProgress?.routeProgress
        XCTAssertEqual(progress2?.legIndex, 1)
        XCTAssertEqual(progress2?.routeId.rawValue, routeId)
        XCTAssertEqual(progress2?.currentLegProgress.stepIndex, 0)
    }

    @MainActor
    func testRouteProgressEventsOnSetToIdle() async {
        let routes = await oneLegNavigationRoutes()
        let expectation = setupRouteProgressExpectation(for: routes.mainRoute.route)

        await startActiveGuidanceAndWaitForState(with: routes)
        await fulfillment(of: [expectation], timeout: timeout)

        let idleExpectation = trackingStatusExpectation(state: .idle)
        let nilRouteProgressExpectation = setupNilRouteProgressExpectation(for: routes.mainRoute.route)
        navigator.setToIdle()
        await fulfillment(of: [nilRouteProgressExpectation, idleExpectation], timeout: timeout)

        // no non-nil route progress updates after setToIdleAsync
        let nextExpectation = setupRouteProgressExpectation(for: routes.mainRoute.route)
        nextExpectation.isInverted = true
        await postStatusUpdateAndVerifyRouteProgress(for: routes.mainRoute.route, expectation: nextExpectation)
    }

    @MainActor
    func testRouteProgressEventsOnStartFreeDrive() async {
        let routes = await oneLegNavigationRoutes()
        let expectation = setupRouteProgressExpectation(for: routes.mainRoute.route)

        await startActiveGuidanceAndWaitForRouteProgressUpdate(with: routes)
        await fulfillment(of: [expectation], timeout: timeout)

        let idleExpectation = trackingStatusExpectation(state: .freeDrive(.active))
        let nilRouteProgressExpectation = setupNilRouteProgressExpectation(for: routes.mainRoute.route)
        navigator.startFreeDrive()
        await fulfillment(of: [nilRouteProgressExpectation, idleExpectation], timeout: timeout)

        // no non-nil route progress updates after startFreeDrive
        let nextExpectation = setupRouteProgressExpectation(for: routes.mainRoute.route)
        nextExpectation.isInverted = true
        await postStatusUpdateAndVerifyRouteProgress(for: routes.mainRoute.route, expectation: nextExpectation)
    }

    @MainActor
    func testRouteProgressEventsActiveGuidanceAfterFreeDrive() async {
        navigator.startFreeDrive()

        let routes = await oneLegNavigationRoutes()
        let expectation = setupRouteProgressExpectation(for: routes.mainRoute.route)

        await startActiveGuidanceAndWaitForRouteProgressUpdate(with: routes)
        await fulfillment(of: [expectation], timeout: timeout)
    }

    // MARK: - Select Alternative Route Tests

    func testSelectAlternativeIfIdleState() async {
        await checkErrorSelectingAlternative(index: 0)
    }

    func testSelectAlternativeIfNoAlternatives() async {
        let navigationRoutes = await NavigationRoutes.mock()
        await startActiveGuidanceAndWaitForState(with: navigationRoutes)
        await checkErrorSelectingAlternative(index: 0)
    }

    func testSelectAlternativeIfNNError() async throws {
        let navigationRoutes = await oneLegNavigationRoutes()
        await startActiveGuidanceAndWaitForState(with: navigationRoutes)
        await checkErrorSelectingAlternative(index: 0)
    }

    func testSelectAlternativeIfCorrectIndex() async {
        let navigationRoutes = await NavigationRoutes.mock(
            mainRoute: .mock(),
            alternativeRoutes: [.mock()]
        )
        mockAlternativesRoutesDataParser()

        await startActiveGuidanceAndWaitForState(with: navigationRoutes)

        let expectation = XCTestExpectation(description: "Alternative started event")
        navigator.continuousAlternatives
            .filter { $0.event is AlternativesStatus.Events.SwitchedToAlternative }
            .sink { _ in expectation.fulfill() }
            .store(in: &subscriptions)
        await navigator.selectAlternativeRoute(at: 0)
        await fulfillment(of: [expectation], timeout: timeout)

        let newRoutes = navigator.currentNavigationRoutes
        XCTAssertEqual(newRoutes?.mainRoute.routeId, navigationRoutes.alternativeRoutes[0].routeId)
    }

    // MARK: - Switch Leg Tests

    func testSwitchLegIfIdleState() async {
        await checkErrorSwitchingLeg(newLegIndex: 1)
    }

    func testSwitchLegIfFreeDrive() async {
        await startFreeDriveAndWaitForState()

        await checkErrorSwitchingLeg(newLegIndex: 1)
        XCTAssertFalse(coreNavigator.updateRouteLegCalled)
    }

    func testSwitchLegWith1Leg() async {
        let navigationRoutes = await NavigationRoutes.mock()
        await startActiveGuidanceAndWaitForRouteProgressUpdate(with: navigationRoutes, startLegIndex: 0)

        await checkErrorSwitchingLeg(newLegIndex: -1)
        await checkErrorSwitchingLeg(newLegIndex: 1)
        XCTAssertFalse(coreNavigator.updateRouteLegCalled)
    }

    func testSwitchLegIfIncorrectLegIndex() async {
        let navigationRoutes = await twoLegNavigationRoutes()
        await startActiveGuidanceAndWaitForRouteProgressUpdate(with: navigationRoutes, startLegIndex: 0)
        await checkErrorSwitchingLeg(newLegIndex: 2)
        XCTAssertFalse(coreNavigator.updateRouteLegCalled)
    }

    func testSwitchLegIfNavNativeError() async {
        let expectation = nextLegStartedExpectation(legIndex: 1)
        expectation.isInverted = true
        let navigationRoutes = await twoLegNavigationRoutes()
        await startActiveGuidanceAndWaitForRouteProgressUpdate(with: navigationRoutes, startLegIndex: 0)

        coreNavigator.updateRouteLegResult = false
        await checkErrorSwitchingLeg(newLegIndex: 1)
        await fulfillment(of: [expectation], timeout: timeout)

        let progress = await navigator.currentRouteProgress?.routeProgress
        XCTAssertEqual(progress?.legIndex, 0)
    }

    func testSwitchLegWithCorrectLegIndex() async {
        let navigationRoutes = await twoLegNavigationRoutes()
        await startActiveGuidanceAndWaitForRouteProgressUpdate(with: navigationRoutes, startLegIndex: 0)

        let expectation = nextLegStartedExpectation(legIndex: 1)
        let billingExpectation = nextLegStartedExpectation(legIndex: 1)
        billingServiceMock.onBeginBillingSession = { _, _ in
            billingExpectation.fulfill()
        }
        navigator.switchLeg(newLegIndex: 1)

        await fulfillment(of: [billingExpectation, expectation], timeout: timeout)

        let progress = await navigator.currentRouteProgress?.routeProgress
        XCTAssertEqual(progress?.legIndex, 1)
        XCTAssertTrue(coreNavigator.updateRouteLegCalled)
        XCTAssertEqual(coreNavigator.passedUpdatedLegIndex, 1)
    }

    func testSwitchLegWithCorrectLegIndexWithoutRouteProgressWaiting() async {
        let navigationRoutes = await twoLegNavigationRoutes()
        await startActiveGuidanceAndWaitForState(with: navigationRoutes)

        let expectation = nextLegStartedExpectation(legIndex: 1)
        let billingExpectation = nextLegStartedExpectation(legIndex: 1)
        billingServiceMock.onBeginBillingSession = { _, _ in
            billingExpectation.fulfill()
        }
        navigator.switchLeg(newLegIndex: 1)

        await fulfillment(of: [billingExpectation, expectation], timeout: timeout)

        let progress = await navigator.currentRouteProgress?.routeProgress
        XCTAssertEqual(progress?.legIndex, 1)
        XCTAssertTrue(coreNavigator.updateRouteLegCalled)
        XCTAssertEqual(coreNavigator.passedUpdatedLegIndex, 1)
    }

    // MARK: - Helpers

    private func errorPublishedExpectation(filter: @escaping (NavigatorError) -> Bool) -> XCTestExpectation {
        let errorExpectation = XCTestExpectation(description: "Leg started event")
        navigator.errors
            .filter(filter)
            .sink { _ in
                errorExpectation.fulfill()
            }
            .store(in: &subscriptions)

        return errorExpectation
    }

    private func checkErrorSelectingAlternative(index: Int) async {
        let errorExpectation = errorPublishedExpectation {
            $0 is NavigatorErrors.FailedToSelectAlternativeRoute
        }
        billingServiceMock.onBeginBillingSession = { _, _ in
            XCTFail("Should not start a billing session")
        }
        await navigator.selectAlternativeRoute(at: index)

        XCTAssertFalse(coreNavigator.updateRouteLegCalled)
        await fulfillment(of: [errorExpectation], timeout: timeout)
        XCTAssertFalse(coreNavigator.updateRouteLegCalled)

        subscriptions.removeAll()
    }

    private func nextLegStartedExpectation(legIndex: Int) -> XCTestExpectation {
        let legStartedExpectation = XCTestExpectation(description: "Leg \(legIndex) started event")
        navigator.waypointsArrival
            .compactMap { $0.event as? WaypointArrivalStatus.Events.NextLegStarted }
            .sink {
                XCTAssertEqual($0, WaypointArrivalStatus.Events.NextLegStarted(newLegIndex: legIndex))
                legStartedExpectation.fulfill()
            }
            .store(in: &subscriptions)

        return legStartedExpectation
    }

    private func checkErrorSwitchingLeg(newLegIndex: Int) async {
        let expectedError = NavigatorErrors.FailedToSelectRouteLeg(legIndex: newLegIndex)
        let errorExpectation = errorPublishedExpectation {
            $0 as? NavigatorErrors.FailedToSelectRouteLeg == expectedError
        }

        let nextLegStartedExpectation = nextLegStartedExpectation(legIndex: 1)
        nextLegStartedExpectation.isInverted = true
        billingServiceMock.onBeginBillingSession = { _, _ in
            XCTFail("Should not start a billing session")
        }
        navigator.switchLeg(newLegIndex: newLegIndex)

        XCTAssertFalse(coreNavigator.updateRouteLegCalled)
        await fulfillment(of: [errorExpectation, nextLegStartedExpectation], timeout: timeout)

        subscriptions.removeAll()
    }

    @MainActor
    private func setupNilRouteProgressExpectation(
        for route: Route
    ) -> XCTestExpectation {
        let routeProgressExpectation = XCTestExpectation(description: "Nil route progress event")
        navigator.routeProgress
            .dropFirst()
            .filter { $0 == nil }
            .sink {
                XCTAssertNil($0)
                routeProgressExpectation.fulfill()
            }
            .store(in: &subscriptions)

        return routeProgressExpectation
    }

    @MainActor
    private func setupRouteProgressExpectation(
        for route: Route
    ) -> XCTestExpectation {
        coreNavigator.navigationStatus = initialNavigationStatus(route: route)
        let routeProgressExpectation = XCTestExpectation(description: "Non-nil route progress event")
        navigator.routeProgress
            .compactMap { $0 }
            .sink { state in
                let routeProgress = state.routeProgress
                XCTAssertEqual(routeProgress.distanceRemaining, route.distance)
                XCTAssertEqual(routeProgress.durationRemaining, route.expectedTravelTime)
                XCTAssertEqual(routeProgress.distanceTraveled, 0)
                XCTAssertEqual(routeProgress.fractionTraveled, 0)
                routeProgressExpectation.fulfill()
            }
            .store(in: &subscriptions)

        return routeProgressExpectation
    }

    private func postStatusUpdateAndVerifyRouteProgress(
        for route: Route,
        expectation: XCTestExpectation
    ) async {
        let status = initialNavigationStatus(route: route)
        let userInfo: [AnyHashable: Any] = [
            NativeNavigator.NotificationUserInfoKey.statusKey: status,
        ]
        let statusNotification = Notification(name: .navigationStatusDidChange, userInfo: userInfo)
        NotificationCenter.default.post(statusNotification)

        await fulfillment(of: [expectation], timeout: timeout)
    }

    private func initialNavigationStatus(route: Route) -> NavigationStatus {
        NavigationStatus.mock(
            activeGuidanceInfo: .mock(
                routeProgress: .mock(
                    remainingDistance: route.distance,
                    remainingDuration: route.expectedTravelTime
                )
            )
        )
    }

    private func trackingStatusExpectation(
        state: Session.State = .activeGuidance(.tracking)
    ) -> XCTestExpectation {
        let trackingStatusExpectation = expectation(description: "Session state \(state) expectation")
        navigator.session
            .filter { $0.state == state }
            .first()
            .sink { _ in trackingStatusExpectation.fulfill() }
            .store(in: &subscriptions)
        return trackingStatusExpectation
    }

    private var refreshedLeg: RouteLeg {
        let steps: [RouteStep] = [
            .mock(maneuverType: .depart),
            .mock(maneuverType: .turn),
            .mock(maneuverType: .turnAtRoundabout),
            .mock(maneuverType: .arrive),
        ]
        var leg = RouteLeg.mock(steps: steps)
        // Set `-1` as coordinateAccuracy to simulate NavigationRouteOptions logic.
        leg.source?.coordinateAccuracy = -1
        leg.destination?.coordinateAccuracy = -1
        return leg
    }

    private func refresh(with notification: Notification) async {
        let startedExpectation = XCTestExpectation(description: "started")
        let refreshedExpectation = XCTestExpectation(description: "refreshed")

        navigator.routeRefreshing
            .filter { $0.event is RefreshingStatus.Events.Refreshing }
            .sink { _ in
                startedExpectation.fulfill()
            }
            .store(in: &subscriptions)
        navigator.routeRefreshing
            .filter { $0.event is RefreshingStatus.Events.Refreshed }
            .sink { _ in
                refreshedExpectation.fulfill()
            }
            .store(in: &subscriptions)

        navigator.didRefreshAnnotations(notification)

        await fulfillment(of: [startedExpectation, refreshedExpectation], timeout: 2)
    }

    private func makeRefreshNotification(
        routeRefreshResult: RouteRefreshResult,
        legIndex: UInt32 = 0
    ) -> Notification {
        let userInfo: [AnyHashable: Any] = [
            NativeNavigator.NotificationUserInfoKey.refreshedRoutesResultKey: routeRefreshResult,
            NativeNavigator.NotificationUserInfoKey.legIndexKey: legIndex,
        ]
        return Notification(name: .routeRefreshDidUpdateAnnotations, userInfo: userInfo)
    }

    private func startActiveGuidanceAndWaitForRouteProgressUpdate(
        with navigationRoutes: NavigationRoutes,
        startLegIndex: Int = 0
    ) async {
        await navigator.startActiveGuidance(with: navigationRoutes, startLegIndex: startLegIndex)
        await waitForRouteProgressUpdate()
    }

    private func waitForRouteProgressUpdate() async {
        routeProgressUpdateExpectation = XCTestExpectation(description: "navigator callback startActiveGuidance")
        await fulfillment(of: [routeProgressUpdateExpectation!], timeout: timeout)
    }

    private func mockAlternativesRoutesDataParser() {
        var routeParserClient = RouteParserClient.testValue
        routeParserClient.createRoutesData = { [weak self] in
            let data = RoutesDataMock.mock(primaryRoute: $0, alternativeRoutes: $1)
            self?.coreNavigator.setRoutesResult = .success((RouteInfo(alerts: []), data.alternativeRoutes()))
            return data
        }
        Environment.set(\.routeParserClient, routeParserClient)
        coreNavigator.setRoutesResult = .success((RouteInfo(alerts: []), []))
    }

    private func setRoutes(
        with navigationRoutes: NavigationRoutes,
        reason: MapboxNavigator.SetRouteReason
    ) async {
        let progress = await navigator.state.privateRouteProgress
        await navigator.setRoutes(
            navigationRoutes: navigationRoutes,
            startLegIndex: 0,
            reason: reason,
            previousRouteProgress: progress
        )
    }

    // Three points along California St in San Fransisco
    private let coordinateA = CLLocationCoordinate2D(latitude: 37.785832, longitude: -122.458148)
    private let coordinateB = CLLocationCoordinate2D(latitude: 37.787594, longitude: -122.444172)
    private let coordinateC = CLLocationCoordinate2D(latitude: 37.78927, longitude: -122.430577)

    private func oneLegNavigationRoutes(
        mapboxApi: MapboxAPI = .directions,
        directionsOptionsType: DirectionsOptions.Type = NavigationRouteOptions.self
    ) async -> NavigationRoutes {
        await mockNavigationRoutes(
            with: [mockLeg(from: coordinateA, to: coordinateC)],
            mapboxApi: mapboxApi,
            directionsOptionsType: directionsOptionsType
        )
    }

    private func twoLegNavigationRoutes(
        mapboxApi: MapboxAPI = .directions,
        directionsOptionsType: DirectionsOptions.Type = NavigationRouteOptions.self
    ) async -> NavigationRoutes {
        await mockNavigationRoutes(
            with: [
                mockLeg(from: coordinateA, to: coordinateB),
                mockLeg(from: coordinateB, to: coordinateC),
            ],
            mapboxApi: mapboxApi,
            directionsOptionsType: directionsOptionsType
        )
    }

    private func mockNavigationRoutes(
        with legs: [RouteLeg],
        mapboxApi: MapboxAPI = .directions,
        directionsOptionsType: DirectionsOptions.Type
    ) async -> NavigationRoutes {
        let route = Route.mock(legs: legs)
        return await NavigationRoutes.mock(mainRoute: .mock(
            route: route,
            nativeRoute: RouteInterfaceMock(route: route, mapboxApi: mapboxApi),
            directionsOptionsType: directionsOptionsType
        ))
    }

    private func mockLeg(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) -> RouteLeg {
        var leg = RouteLeg.mock()
        leg.source = Waypoint(coordinate: source)
        leg.destination = Waypoint(coordinate: destination)
        return leg
    }

    private func startFreeDriveAndWaitForState() async {
        let freeDriveExpectation = trackingStatusExpectation(state: .freeDrive(.active))
        await navigator.startFreeDrive()
        await fulfillment(of: [freeDriveExpectation], timeout: timeout)
    }

    private func setToIdleAndWaitForState() async {
        let idleExpectation = trackingStatusExpectation(state: .idle)
        await navigator.setToIdle()
        await fulfillment(of: [idleExpectation], timeout: timeout)
    }

    private func startActiveGuidanceAndWaitForState(
        with routes: NavigationRoutes,
        startLegIndex: Int = 0
    ) async {
        let activeGuidanceExpectation = trackingStatusExpectation(state: .activeGuidance(.uncertain))
        await navigator.startActiveGuidance(with: routes, startLegIndex: startLegIndex)
        await fulfillment(of: [activeGuidanceExpectation], timeout: timeout)
    }
}
