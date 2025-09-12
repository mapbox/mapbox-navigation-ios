import _MapboxNavigationTestHelpers
import Combine
import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
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

    var routeProgressExpectation: XCTestExpectation?

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

        routeProgressExpectation = nil
        navigator.routeProgress
            .dropFirst()
            .sink(receiveValue: { [weak self] _ in
                self?.routeProgressExpectation?.fulfill()
            })
            .store(in: &subscriptions)
    }

    override func tearDown() {
        Environment.switchEnvironment(to: .live)
        super.tearDown()
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
        await navigator.startActiveGuidanceAsync(with: navigationRoutes, startLegIndex: 0)
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
                navigator.didRefreshAnnotations(refreshNotification)
                await navigator.setRoutes(
                    navigationRoutes: navigationRoutes,
                    startLegIndex: 0,
                    reason: .reroute,
                    previousRouteProgress: routeProgress
                )
            }
        }
        XCTAssertTrue(navigator.currentSession.state.isTripSessionActive)
    }

    func testUpdateMapMatchingResult() async {
        let enhancedLocation = CLLocation(latitude: 1.0, longitude: 2.0)
        let rawLocation = CLLocation(latitude: 3.0, longitude: 4.0)
        coreNavigator.rawLocation = rawLocation
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
        try? await navigator.startFreeDriveAsync()
        await navigator.setToIdleAsync()
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
        await navigator.startActiveGuidanceAsync(with: .mock(), startLegIndex: 0)
        await navigator.setToIdleAsync()
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
    func testStartActiveGuidanceAsync() async {
        await navigator.startActiveGuidanceAsync(with: .mock(), startLegIndex: 0)
        let state = navigator.currentSession.state
        // TODO: (NAVIOS-2155) set active guidance state before returning from startActiveGuidance
        XCTAssertEqual(state, .idle)
        XCTAssertFalse(coreNavigator.unsetRoutesCalled)
        XCTAssertTrue(coreNavigator.setRoutesCalled)
        XCTAssertTrue(locationClientState.updatingHeading)
        XCTAssertTrue(locationClientState.updatingLocation)
        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .activeGuidance), .running)
        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .freeDrive), .stopped)
        billingServiceMock.assertEvents([
            .beginBillingSession(.activeGuidance),
        ])
    }

    @MainActor
    func testSetStateToFreeDriveAsync() async {
        await navigator.setToIdleAsync()
        try? await navigator.startFreeDriveAsync()
        let state = navigator.currentSession.state
        XCTAssertEqual(state, .freeDrive(.active))
        XCTAssertTrue(locationClientState.updatingHeading)
        XCTAssertTrue(locationClientState.updatingLocation)
        XCTAssertEqual(billingServiceMock.getSessionStatus(for: .freeDrive), .running)
    }

    func testPauseAndResumeActiveGuidanceSessionAsync() async {
        await navigator.startActiveGuidanceAsync(with: .mock(), startLegIndex: 0)
        await navigator.setToIdleAsync()
        await navigator.startActiveGuidanceAsync(with: .mock(), startLegIndex: 0)

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

        await navigator.startActiveGuidanceAsync(with: routes, startLegIndex: 1)
        await navigator.setToIdleAsync()
        await navigator.startActiveGuidanceAsync(with: routes, startLegIndex: 1)

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

        await navigator.startActiveGuidanceAsync(with: routes, startLegIndex: 1)
        await navigator.setToIdleAsync()
        await navigator.startActiveGuidanceAsync(with: routes, startLegIndex: 2)

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
    func testPauseAndStartActiveGuidanceSessionWhenFreeDriveAsync() async {
        await navigator.startActiveGuidanceAsync(with: .mock(), startLegIndex: 0)
        await navigator.setToIdleAsync()
        try? await navigator.startFreeDriveAsync()
        await navigator.startActiveGuidanceAsync(with: .mock(), startLegIndex: 0)

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
        await navigator.startActiveGuidanceAsync(with: .mock(), startLegIndex: 0)
        await navigator.setToIdleAsync()
        var leg = RouteLeg.mock()
        leg.destination = Waypoint(coordinate: .init(latitude: 1.5, longitude: 2.5))
        let routes = await NavigationRoutes.mock(
            mainRoute: .mock(route: .mock(legs: [leg]))
        )
        await navigator.startActiveGuidanceAsync(with: routes, startLegIndex: 0)

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
        await navigator.startActiveGuidanceAsync(with: .mock(), startLegIndex: 0)
        await navigator.setToIdleAsync()
        var leg = RouteLeg.mock()
        leg.destination = Waypoint(coordinate: .init(latitude: 1.0005, longitude: 2.0005))
        let routes = await NavigationRoutes.mock(
            mainRoute: .mock(route: .mock(legs: [leg]))
        )
        await navigator.startActiveGuidanceAsync(with: routes, startLegIndex: 0)

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
        await startActiveGuidanceAndWaitForRouteProgress(with: oneLegNavigationRoutes())
        await setRoutes(with: oneLegNavigationRoutes(), reason: .newRoute)

        billingServiceMock.assertEvents([.beginBillingSession(.activeGuidance)])
    }

    @MainActor
    func testSetRoutesSimilarRerouteKeepsSession() async {
        await startActiveGuidanceAndWaitForRouteProgress(with: oneLegNavigationRoutes())
        await setRoutes(with: oneLegNavigationRoutes(), reason: .reroute)

        billingServiceMock.assertEvents([.beginBillingSession(.activeGuidance)])
    }

    @MainActor
    func testSetRoutesDifferentNewRouteBeginsNewSession() async {
        await startActiveGuidanceAndWaitForRouteProgress(with: twoLegNavigationRoutes())
        await setRoutes(with: oneLegNavigationRoutes(), reason: .newRoute)

        billingServiceMock.assertEvents([
            .beginBillingSession(.activeGuidance),
            .stopBillingSession(.activeGuidance),
            .beginBillingSession(.activeGuidance),
        ])
    }

    @MainActor
    func testSetRoutesDifferentRerouteBeginsNewSession() async {
        await startActiveGuidanceAndWaitForRouteProgress(with: twoLegNavigationRoutes())
        await setRoutes(with: oneLegNavigationRoutes(), reason: .reroute)

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
        await startActiveGuidanceAndWaitForRouteProgress(with: twoLegNavigationRoutes(mapboxApi: .mapMatching))
        await setRoutes(with: oneLegNavigationRoutes(mapboxApi: .directions), reason: .reroute)

        billingServiceMock.assertEvents([.beginBillingSession(.activeGuidance)])
    }

    func testRefreshMainRoute() async {
        let originalRoutes = await NavigationRoutes.mock(
            mainRoute: .mock(),
            alternativeRoutes: [.mock()]
        )
        mockAlternativesRoutesDataParser()
        await navigator.startActiveGuidanceAsync(with: originalRoutes, startLegIndex: 0)
        await waitForRouteProgress()

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
        await navigator.startActiveGuidanceAsync(with: originalRoutes, startLegIndex: 0)
        await waitForRouteProgress()

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
        await navigator.startActiveGuidanceAsync(with: originalRoutes, startLegIndex: 1)
        await waitForRouteProgress()
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
        await startActiveGuidanceAndWaitForRouteProgress(with: oneLegNavigationRoutes())
        let route = RouteInterfaceMock()
        navigator.rerouteControllerWantsSwitchToAlternative(rerouteController, route: route, legIndex: 0)
        await waitForRouteProgress()

        XCTAssertTrue(coreNavigator.setRoutesCalled)
        XCTAssertEqual(coreNavigator.passedSetReason, .alternative)

        let currentRoutes = navigator.currentNavigationRoutes!
        let expectedOptions = route.getResponseOptions(NavigationRouteOptions.self)!
        XCTAssertEqual(currentRoutes.mainRoute.nativeRouteInterface.getRouteId(), route.getRouteId())
        XCTAssertEqual(currentRoutes.mainRoute.requestOptions, expectedOptions)
    }

    func testRerouteControllerWantsSwitchToAlternativeIfCustomOptions() async {
        let initialRoutes = await oneLegNavigationRoutes(directionsOptionsType: GolfCartRouteOptions.self)
        await startActiveGuidanceAndWaitForRouteProgress(with: initialRoutes)
        let route = RouteInterfaceMock()
        navigator.rerouteControllerWantsSwitchToAlternative(rerouteController, route: route, legIndex: 0)
        await waitForRouteProgress()

        XCTAssertTrue(coreNavigator.setRoutesCalled)
        XCTAssertEqual(coreNavigator.passedSetReason, .alternative)

        let currentRoutes = navigator.currentNavigationRoutes!
        XCTAssertEqual(currentRoutes.mainRoute.nativeRouteInterface.getRouteId(), route.getRouteId())
        XCTAssertTrue(type(of: currentRoutes.mainRoute.directionOptions) == GolfCartRouteOptions.self)
    }

    // MARK: - Helpers

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

    private func startActiveGuidanceAndWaitForRouteProgress(
        with navigationRoutes: NavigationRoutes,
        startLegIndex: Int = 0
    ) async {
        await navigator.startActiveGuidance(with: navigationRoutes, startLegIndex: startLegIndex)
        await waitForRouteProgress()
    }

    private func waitForRouteProgress() async {
        routeProgressExpectation = XCTestExpectation(description: "route progress after startActiveGuidance")
        await fulfillment(of: [routeProgressExpectation!], timeout: timeout)
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
        let progress = await navigator.currentRouteProgress?.routeProgress
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
        await NavigationRoutes.mock(mainRoute: .mock(
            route: .mock(legs: legs),
            nativeRoute: RouteInterfaceMock(mapboxApi: mapboxApi),
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
}
