@testable import _MapboxNavigationTestHelpers
import Combine
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private
import XCTest

final class ContinuousAlternativesRouteIntegrationTests: BaseIntegrationTest {
    let origin = CLLocationCoordinate2D(latitude: 40.76050975068355, longitude: -73.98778274913309)
    let destination = CLLocationCoordinate2D(latitude: 40.75988085727627, longitude: -73.98039053825985)

    let routeId = "JZdoNhmdt5P6NDBbQM058Z6jvVeZV_83DvFYUuc_JfcdysWHayQ==_eu-west-1"

    var navigationRoutes: NavigationRoutes!

    @MainActor
    override func setUp() {
        super.setUp()

        coreConfig.routingConfig.alternativeRoutesDetectionConfig = .init(refreshIntervalSeconds: 3)
        navigationProvider.apply(coreConfig: coreConfig)
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

        let tripSession = await navigationProvider.tripSession()
        let statusExpectation = await trackingStatusExpectation()
        let locations = routes.mainRoute.route.simulationOnRouteLocations
        let locationsToSimulate = Array(locations.prefix(2))
        let refreshEventExpectation1 = await refreshExpectation(shouldRefresh: shouldRefresh)
        refreshEventExpectation1.assertForOverFulfill = false
        let refreshExpectation0 = makeRouteRefreshRequestExpectation(
            index: 0,
            shouldRefresh: shouldRefresh
        )
        let refreshExpectation1 = makeRouteRefreshRequestExpectation(
            index: 1,
            shouldRefresh: shouldRefresh
        )
        let refreshExpectation2 = makeRouteRefreshRequestExpectation(
            index: 2,
            shouldRefresh: shouldRefresh
        )

        await tripSession.startActiveGuidance(with: routes, startLegIndex: 0)
        await simulateLocations(locationsToSimulate)

        stubRouteResponse("alternatives-route-2") {
            shouldUseCustomOptions ? $0.contains("custom=customValue") : true
        }
        let expectations1 = [
            statusExpectation, refreshExpectation1,
            refreshExpectation0, refreshExpectation2,
            refreshEventExpectation1,
        ]
        await fulfillment(of: expectations1, timeout: defaultDelay)

        cancellables = []
        let refreshEventExpectation2 = await refreshExpectation(shouldRefresh: shouldRefresh)
        refreshEventExpectation2.assertForOverFulfill = false
        let refreshRequestExpectation = makeRouteRefreshRequestExpectation(
            index: shouldSelectAlternative ? 1 : 0,
            shouldRefresh: shouldRefresh,
            requestNumber: 2
        )
        let expectations2 = [
            refreshRequestExpectation,
            refreshEventExpectation2,
        ]
        let locationsToSimulate2 = Array(locations[3..<30])
        await simulateLocations(locationsToSimulate2)
        await fulfillment(of: expectations2, timeout: defaultDelay)
    }

    fileprivate func makeRouteRefreshRequestExpectation(
        index: Int,
        shouldRefresh: Bool,
        requestNumber: Int = 1
    ) -> XCTestExpectation {
        let expectation = expectation(description: "Route refresh for index=\(index) called")
        expectation.isInverted = !shouldRefresh
        expectation.assertForOverFulfill = false

        let expectedSubstring = "\(routeId)/\(index)/0"
        stubRouteRefreshResponse("alternatives-route-\(requestNumber)-refresh-\(index)") { url in
            let result = url.contains(expectedSubstring)
            if result {
                expectation.fulfill()
            }
            return result
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
}
