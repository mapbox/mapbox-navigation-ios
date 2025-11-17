@testable import _MapboxNavigationTestHelpers
import Combine
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private
import XCTest

final class RouteRefreshIntegrationTests: BaseIntegrationTest {
    let origin = CLLocationCoordinate2D(latitude: 40.76050975068355, longitude: -73.98778274913309)
    let destination = CLLocationCoordinate2D(latitude: 40.75988085727627, longitude: -73.98039053825985)

    var navigationRoutes: NavigationRoutes!

    @MainActor
    override func setUp() {
        super.setUp()

        stubRouteRefreshResponse("profile-route-refresh")
    }

    // MARK: Refresh

    func testRouteRefreshWithDrivingTrafficProfile() async {
        await simulateAndTestOnRoute(with: .automobileAvoidingTraffic, shouldRefresh: true)
    }

    func testRouteRefreshWithCustomDrivingTrafficProfile() async {
        await simulateAndTestOnRoute(with: customDrivingTraffic, shouldRefresh: true)
    }

    func testRouteRefreshWithDrivingProfile() async {
        await simulateAndTestOnRoute(with: .automobile, shouldRefresh: false)
    }

    func testRouteRefreshWithCustomDrivingProfile() async {
        await simulateAndTestOnRoute(with: customDriving, shouldRefresh: false)
    }

    func testRouteRefreshWithWalkingProfile() async {
        await simulateAndTestOnRoute(with: .walking, shouldRefresh: false)
    }

    func testRouteRefreshWithCyclingProfile() async {
        await simulateAndTestOnRoute(with: .cycling, shouldRefresh: false)
    }

    func testRouteRefreshWithDrivingTrafficProfileAndCustomParameter() async {
        await simulateAndTestOnRoute(
            with: .automobileAvoidingTraffic,
            shouldRefresh: true,
            shouldUseCustomOptions: true
        )
    }

    func testRouteRefreshWithCustomDrivingTrafficProfileAndCustomParameter() async {
        await simulateAndTestOnRoute(
            with: customDrivingTraffic,
            shouldRefresh: true,
            shouldUseCustomOptions: true
        )
    }

    // MARK: Refresh after reroute

    func testRouteRefreshAfterRerouteWithDrivingTrafficProfile() async {
        await simulateAndTestOffRoute(with: .automobileAvoidingTraffic, shouldRefresh: true)
    }

    func testRouteRefreshAfterRerouteWithCustomDrivingTrafficProfile() async {
        await simulateAndTestOffRoute(with: customDrivingTraffic, shouldRefresh: true)
    }

    func testRouteRefreshAfterRerouteWithDrivingProfile() async {
        await simulateAndTestOffRoute(with: .automobile, shouldRefresh: false)
    }

    func testRouteRefreshAfterRerouteWithWalkingProfile() async {
        await simulateAndTestOffRoute(with: .walking, shouldRefresh: false)
    }

    func testRouteRefreshAfterRerouteWithCyclingProfile() async {
        await simulateAndTestOffRoute(with: .cycling, shouldRefresh: false)
    }

    func testRouteRefreshAfterRerouteWithDrivingTrafficProfileAndCustomParameter() async {
        await simulateAndTestOffRoute(
            with: .automobileAvoidingTraffic,
            shouldRefresh: true,
            shouldUseCustomOptions: true
        )
    }

    func testRouteRefreshAfterRerouteWithCustomDrivingTrafficProfileAndCustomParameter() async {
        await simulateAndTestOffRoute(
            with: customDrivingTraffic,
            shouldRefresh: true,
            shouldUseCustomOptions: true
        )
    }

    // MARK: Pausing refreshes

    func testPauseAndResumeRefreshes() async {
        await simulateAndTestOnRoute(
            with: .automobileAvoidingTraffic,
            shouldRefresh: true,
            skipLocationsCount: 5
        )

        cancellables = []
        await navigationProvider.tripSession().setToIdle()
        let idleNoRefreshExpectation = await refreshExpectation(shouldRefresh: false)
        await waitForIdle()
        await fulfillment(of: [idleNoRefreshExpectation], timeout: defaultDelay)

        cancellables = []
        let statusExpectation = await trackingStatusExpectation()
        let resumedRefreshExpectation = await refreshExpectation(shouldRefresh: true)
        await navigationProvider.tripSession().startActiveGuidance(with: navigationRoutes, startLegIndex: 0)
        let locations = navigationRoutes.mainRoute.route.simulationOnRouteLocations
        await simulateLocations(locations)
        await fulfillment(of: [statusExpectation, resumedRefreshExpectation], timeout: defaultDelay)
    }

    // MARK: Helpers

    @MainActor
    fileprivate func waitForIdle() async {
        let tripSession = navigationProvider.tripSession()
        guard tripSession.currentSession.state != .idle else {
            return
        }
        let idleExpectation = await trackingStatusExpectation(state: .idle)
        await fulfillment(of: [idleExpectation], timeout: defaultDelay)
    }

    fileprivate func defaultOptions(with profile: ProfileIdentifier) -> NavigationRouteOptions {
        NavigationRouteOptions(coordinates: [origin, destination], profileIdentifier: profile)
    }

    fileprivate func customOptions(
        with profile: ProfileIdentifier,
        custom: String? = "customValue"
    ) -> CustomRouteOptions {
        let options = CustomRouteOptions(coordinates: [origin, destination], profileIdentifier: profile)
        options.custom = custom
        return options
    }

    private func simulateAndTestOnRoute(
        with profile: ProfileIdentifier,
        shouldRefresh: Bool,
        skipLocationsCount: Int = 0,
        shouldUseCustomOptions: Bool = false
    ) async {
        let options = shouldUseCustomOptions ? customOptions(with: profile) : defaultOptions(with: profile)
        let routes = await NavigationRoutes.mock(options: options, fileName: "profile-route-original")
        navigationRoutes = routes

        let tripSession = await navigationProvider.tripSession()
        let statusExpectation = await trackingStatusExpectation()
        await tripSession.startActiveGuidance(with: routes, startLegIndex: 0)
        let locations = routes.mainRoute.route.simulationOnRouteLocations
        let locationsToSimulate = Array(locations.dropLast(skipLocationsCount))
        let expectation = await refreshExpectation(shouldRefresh: shouldRefresh)

        await simulateLocations(locationsToSimulate)
        await fulfillment(of: [statusExpectation, expectation], timeout: defaultDelay)
    }

    private func simulateAndTestOffRoute(
        with profile: ProfileIdentifier,
        shouldRefresh: Bool,
        shouldUseCustomOptions: Bool = false
    ) async {
        let options = shouldUseCustomOptions ? customOptions(with: profile) : defaultOptions(with: profile)
        let routes = await NavigationRoutes.mock(options: options, fileName: "profile-route-reroute")
        navigationRoutes = routes

        let tripSession = await navigationProvider.tripSession()
        await tripSession.startActiveGuidance(with: routes, startLegIndex: 0)
        let rerouteRoutes = await NavigationRoutes.mock(options: options, fileName: "profile-route-original")
        stubRerouteResponse("profile-route-original", shouldUseCustomOptions: shouldUseCustomOptions)

        let statusExpectation = await trackingStatusExpectation()
        let locations = rerouteRoutes.mainRoute.route.simulationOnRouteLocations
        let firstLocations = Array(locations.prefix(10))
        let afterRerouteLocations = Array(locations.dropFirst(10))
        let expectation1 = await rerouteExpectation()
        await simulateLocations(firstLocations)
        await fulfillment(of: [statusExpectation, expectation1], timeout: defaultDelay)

        let expectation2 = await refreshExpectation(shouldRefresh: shouldRefresh)
        await simulateLocations(afterRerouteLocations)
        await fulfillment(of: [expectation2], timeout: defaultDelay)
    }

    private func stubRerouteResponse(_ fileName: String, shouldUseCustomOptions: Bool) {
        stubRouteResponse(fileName) {
            shouldUseCustomOptions ? $0.contains("custom=customValue") : true
        }
    }
}
