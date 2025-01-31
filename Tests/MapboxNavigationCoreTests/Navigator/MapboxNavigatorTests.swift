import _MapboxNavigationTestHelpers
import Combine
import CoreLocation
@testable import MapboxNavigationCore
import MapboxNavigationNative
import XCTest

final class MapboxNavigatorTests: TestCase {
    var navigator: MapboxNavigator!
    var coreNavigator: CoreNavigatorMock!
    var subscriptions: Set<AnyCancellable>!
    var refreshNotification: Notification!
    var routeRefreshResult: RouteRefreshResult!
    let timeout: TimeInterval = 0.5

    override func setUp() async throws {
        try? await super.setUp()

        subscriptions = []
        coreNavigator = await CoreNavigatorMock()
        coreNavigator.setRoutesResult = .success((RouteInfo(alerts: []), []))
        routeRefreshResult = RouteRefreshResult(
            updatedRoute: RouteInterfaceMock(),
            alternativeRoutes: []
        )
        let userInfo: [AnyHashable: Any] = [
            NativeNavigator.NotificationUserInfoKey.refreshedRoutesResultKey: routeRefreshResult!,
            NativeNavigator.NotificationUserInfoKey.legIndexKey: 0,
        ]
        refreshNotification = Notification(name: .routeRefreshDidUpdateAnnotations, userInfo: userInfo)
        let coonfiguration = MapboxNavigator.Configuration(
            navigator: coreNavigator,
            routeParserType: RouteParser.self,
            locationClient: .mockLocationClient(locationPublisher: locationPublisher.eraseToAnyPublisher()),
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
    }

    @MainActor
    func testStartActiveGuidanceAndRefresh() async {
        XCTAssertFalse(navigator.currentSession.state.isTripSessionActive)

        let navigationRoutes = await NavigationRoutes.mock()
        navigator.privateSession.emit(Session(state: .activeGuidance(.initialized)))

        for _ in 0..<100 {
            navigator.startActiveGuidance(with: navigationRoutes, startLegIndex: 0)
            navigator.setRoutes(navigationRoutes: navigationRoutes, startLegIndex: 0, reason: .newRoute)
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
                NotificationCenter.default.post(statusNotification)
                await self?.navigator.setRoutes(navigationRoutes: navigationRoutes, startLegIndex: 0, reason: .newRoute)
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
                await navigator.setRoutes(navigationRoutes: navigationRoutes, startLegIndex: 0, reason: .reroute)
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
}
