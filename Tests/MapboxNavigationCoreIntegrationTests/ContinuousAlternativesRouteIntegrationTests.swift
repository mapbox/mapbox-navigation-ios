@testable import _MapboxNavigationTestHelpers
import Combine
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private
import XCTest

final class ContinuousAlternativesRouteIntegrationTests: BaseIntegrationTest {
    let origin = CLLocationCoordinate2D(latitude: 40.76050975068355, longitude: -73.98778274913309)
    let destination = CLLocationCoordinate2D(latitude: 40.75988085727627, longitude: -73.98039053825985)

    /// Full Directions uuid from `alternatives-route-1.json`.
    let routeId = "Cw-JZdoNhmdt5P6NDBbQM058Z6jvVeZV_83DvFYUuc_JfcdysWHayQ==_eu-west-1"

    /// Long enough for tracking + a 1s refresh period after NN keeps CA on `setAlternativeRoutes`.
    let refreshTimeout: TimeInterval = 15

    var navigationRoutes: NavigationRoutes!

    @MainActor
    override func makeBaseCoreConfig(credentials: NavigationCoreApiConfiguration) -> CoreConfig {
        var config = super.makeBaseCoreConfig(credentials: credentials)
        config.routingConfig.alternativeRoutesDetectionConfig = .init(refreshIntervalSeconds: 3)
        config.routingConfig.ignoreExpirationTimeInRefresh = true
        return config
    }

    @MainActor
    override func setUp() {
        super.setUp()
        stubRouteResponse("alternatives-route-1")
    }

    func testRouteRefreshWithDrivingTrafficProfile() async {
        await simulateAndTestOnRoute(with: .automobileAvoidingTraffic, shouldRefresh: true)
    }

    func testRouteRefreshWithDrivingTrafficProfileAfterSelectingAlternative() async {
        await simulateAndTestOnRoute(
            with: .automobileAvoidingTraffic,
            shouldRefresh: true,
            shouldSelectAlternative: true
        )
    }

    func testRouteRefreshWithDrivingTrafficProfileAndCustomOptions() async {
        await simulateAndTestOnRoute(
            with: .automobileAvoidingTraffic,
            shouldRefresh: true,
            shouldUseCustomOptions: true
        )
    }

    func testRouteRefreshWithCustomDrivingTrafficProfile() async {
        await simulateAndTestOnRoute(with: customDrivingTraffic, shouldRefresh: true)
    }

    func testRouteRefreshWithCustomDrivingTrafficProfileAndCustomOptions() async {
        await simulateAndTestOnRoute(with: customDrivingTraffic, shouldRefresh: true, shouldUseCustomOptions: true)
    }

    func testRouteRefreshWithDrivingTrafficProfileAndCustomOptionsAfterSelectingAlternative() async {
        await simulateAndTestOnRoute(
            with: .automobileAvoidingTraffic,
            shouldRefresh: true,
            shouldUseCustomOptions: true,
            shouldSelectAlternative: true
        )
    }

    func testRouteRefreshWithDrivingProfile() async {
        await simulateAndTestOnRoute(with: .automobile, shouldRefresh: false)
    }

    func testRouteRefreshWithCustomDrivingProfile() async {
        await simulateAndTestOnRoute(with: customDriving, shouldRefresh: false)
    }

    func testSwitchingToAlternative() async throws {
        var cancellables = Set<AnyCancellable>()
        let options = makeDefaultOptions(with: .automobileAvoidingTraffic)
        let navigationRoutes = await NavigationRoutes.mock(options: options, fileName: "alternatives-route-1")

        let navigator = await navigationProvider.mapboxNavigation.navigation()

        // Start AG
        let activeGuidanceExpectation = expectation(description: "Active guidance started.")
        await navigationProvider.mapboxNavigation.tripSession().session
            .sink(receiveValue: { session in
                if case .activeGuidance = session.state {
                    activeGuidanceExpectation.fulfill()
                }
            })
            .store(in: &cancellables)
        await navigationProvider.mapboxNavigation.tripSession()
            .startActiveGuidance(with: navigationRoutes, startLegIndex: 0)

        await fulfillment(of: [activeGuidanceExpectation], timeout: defaultDelay)

        // Pick an alternative
        let alternativesSwitchExpectation = expectation(description: "Alternative is switched")
        await navigator.selectAlternativeRoute(at: 0)
        await navigator.continuousAlternatives.sink { status in
            XCTAssertTrue(
                status.event is AlternativesStatus.Events.SwitchedToAlternative,
                "Did not switch to the alternative."
            )
            alternativesSwitchExpectation.fulfill()
        }
        .store(in: &cancellables)

        await fulfillment(of: [alternativesSwitchExpectation], timeout: defaultDelay)
    }

    private func simulateAndTestOnRoute(
        with profile: ProfileIdentifier,
        shouldRefresh: Bool,
        shouldUseCustomOptions: Bool = false,
        shouldSelectAlternative: Bool = false
    ) async {
        let options = shouldUseCustomOptions ? makeCustomOptions(with: profile) : makeDefaultOptions(with: profile)
        let originalRoutes = await NavigationRoutes.mock(options: options, fileName: "alternatives-route-1")
        let routes: NavigationRoutes
        if shouldSelectAlternative {
            guard let selectedAlternativeRoutes = await originalRoutes.selectingAlternativeRoute(at: 0),
                  selectedAlternativeRoutes.alternativeRoutes.count == 2
            else {
                XCTFail("Failed to select an alternative route")
                return
            }
            routes = selectedAlternativeRoutes
        } else {
            routes = originalRoutes
        }
        navigationRoutes = routes

        // Refresh schedules the primary and every alternative. Stub all of those URLs so they
        // never hit Directions; only wait on the active index (uuid/0, or uuid/1 after selecting
        // an alternative). A later passed-alternative CA can drop the other original indices.
        let activeIndex = shouldSelectAlternative ? 1 : 0
        let waitTimeout = shouldRefresh ? refreshTimeout : defaultDelay
        let tripSession = await navigationProvider.tripSession()
        let statusExpectation = await trackingStatusExpectation()
        let locations = routes.mainRoute.route.simulationOnRouteLocations
        let firstLocations = Array(locations.prefix(15))
        let refreshEventExpectation1 = await refreshExpectation(shouldRefresh: shouldRefresh)
        refreshEventExpectation1.assertForOverFulfill = false
        let refreshRequestExpectation1 = stubRouteRefreshResponses(
            indices: [0, 1, 2],
            assertedIndex: activeIndex,
            shouldRefresh: shouldRefresh
        )

        let routeProgressExpectation = await routeProgressExpectation(for: routes.mainRoute.route)
        await tripSession.startActiveGuidance(with: routes, startLegIndex: 0)
        await simulateLocations(firstLocations)

        await fulfillment(
            of: [
                routeProgressExpectation,
                statusExpectation,
                refreshRequestExpectation1,
                refreshEventExpectation1,
            ],
            timeout: waitTimeout
        )

        // Retain-only CA body; install it only after the original-route refresh is proven.
        // This expectation confirms that the stub intercepted the request; Native applies the response asynchronously.
        let alternativesRequestExpectation = expectation(description: "Retain-only CA route requested")
        alternativesRequestExpectation.assertForOverFulfill = false
        stubRouteResponse("alternatives-route-2") {
            let matches = shouldUseCustomOptions ? $0.contains("custom=customValue") : true
            if matches {
                alternativesRequestExpectation.fulfill()
            }
            return matches
        }

        // Ten points pass this fixture's alternative fork while staying away from the destination,
        // where Native stops requesting alternatives.
        let postCAProgressLocations = Array(locations.dropFirst(firstLocations.count).prefix(10))
        guard let holdingLocation = postCAProgressLocations.last else {
            XCTFail("Not enough locations to simulate the post-CA refresh")
            return
        }
        await simulateLocations(postCAProgressLocations)
        await fulfillment(of: [alternativesRequestExpectation], timeout: waitTimeout)

        cancellables = []
        let refreshEventExpectation2 = await refreshExpectation(shouldRefresh: shouldRefresh)
        refreshEventExpectation2.assertForOverFulfill = false
        // Retain-only CA keeps primary 0 and original index 1; stub both, assert the active one.
        let refreshRequestExpectation2 = stubRouteRefreshResponses(
            indices: [0, 1],
            assertedIndex: activeIndex,
            shouldRefresh: shouldRefresh,
            requestNumber: 2
        )
        // Hold position for 30 × 50 ms = 1.5 seconds, longer than the 1-second refresh period.
        // Advance timestamps so Native does not reject repeated coordinates as stale.
        let holdingLocations = Array(repeating: holdingLocation, count: 30)
            .shifted(to: holdingLocation.timestamp.addingTimeInterval(1))
        await simulateLocations(holdingLocations)
        await fulfillment(
            of: [
                refreshRequestExpectation2,
                refreshEventExpectation2,
            ],
            timeout: waitTimeout
        )
    }

    fileprivate func stubRouteRefreshResponses(
        indices: [Int],
        assertedIndex: Int,
        shouldRefresh: Bool,
        requestNumber: Int = 1
    ) -> XCTestExpectation {
        let expectation = expectation(description: "Route refresh for index=\(assertedIndex) called")
        expectation.isInverted = !shouldRefresh
        expectation.assertForOverFulfill = false

        for index in indices {
            let expectedSubstring = "\(routeId)/\(index)/0"
            stubRouteRefreshResponse("alternatives-route-\(requestNumber)-refresh-\(index)") { url in
                let matched = url.contains(expectedSubstring)
                if matched, index == assertedIndex {
                    expectation.fulfill()
                }
                return matched
            }
        }

        return expectation
    }

    fileprivate func makeDefaultOptions(with profile: ProfileIdentifier) -> NavigationRouteOptions {
        NavigationRouteOptions(coordinates: [origin, destination], profileIdentifier: profile)
    }

    fileprivate func makeCustomOptions(
        with profile: ProfileIdentifier,
        custom: String? = "customValue"
    ) -> CustomRouteOptions {
        let options = CustomRouteOptions(coordinates: [origin, destination], profileIdentifier: profile)
        options.custom = custom
        return options
    }

    fileprivate func routeProgressExpectation(
        for route: Route
    ) async -> XCTestExpectation {
        let routeProgressExpectation = XCTestExpectation(description: "Non-nil route progress event")
        await navigationProvider.navigator().routeProgress
            .compactMap { $0 }
            .first()
            .sink { state in
                let routeProgress = state.routeProgress
                XCTAssertTrue(routeProgress.distanceRemaining > 0)
                XCTAssertTrue(routeProgress.durationRemaining > 0)
                routeProgressExpectation.fulfill()
            }
            .store(in: &cancellables)
        return routeProgressExpectation
    }
}
