@testable import _MapboxNavigationTestHelpers
import Combine
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private
import OHHTTPStubs
import XCTest

final class RouteRefreshIntegrationTests: BaseTestCase {
    let origin = CLLocationCoordinate2D(latitude: -73.98778274913309, longitude: 40.76050975068355)
    let destiantion = CLLocationCoordinate2D(latitude: -73.98039053825985, longitude: 40.75988085727627)
    let customDrivingTraffic = ProfileIdentifier(rawValue: "custom/driving-traffic")
    let customDriving = ProfileIdentifier(rawValue: "custom/driving")
    let defaultDelay: TimeInterval = 1

    var navigationProvider: MapboxNavigationProvider!
    var billingServiceMock: BillingServiceMock!
    @MainActor
    var locationPublisher: CurrentValueSubject<CLLocation, Never>!
    var cancellables: Set<AnyCancellable>!

    @MainActor
    override func setUp() {
        super.setUp()

        cancellables = []
        let mockData = responseJsonData(bundle: .module, fileName: "profile-route-refresh")!
        HTTPStubs.stubRequests(
            passingTest: { request -> Bool in
                request.url?.absoluteString.contains("directions-refresh") ?? false
            }
        ) { _ -> HTTPStubsResponse in
            HTTPStubsResponse(
                data: mockData,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }

        Credentials.injectSharedToken()
        billingServiceMock = .init()
        let billingHandler = BillingHandler.__createMockedHandler(with: billingServiceMock)
        let credentials = NavigationCoreApiConfiguration(accessToken: .mockedAccessToken)
        var coreConfig = CoreConfig(
            credentials: credentials,
            routingConfig: .init(routeRefreshPeriod: 1)
        )
        let location = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        locationPublisher = .init(location)
        coreConfig.__customBillingHandler = BillingHandlerProvider(billingHandler)
        coreConfig.locationSource = .custom(.mock(locationPublisher.eraseToAnyPublisher()))
        navigationProvider = MapboxNavigationProvider(coreConfig: coreConfig)
    }

    @MainActor
    override func tearDown() {
        HTTPStubs.removeAllStubs()
        navigationProvider.tripSession().setToIdle()
        navigationProvider = nil
        super.tearDown()
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

    // MARK: Refresh after reroute

    func disabled_testRouteRefreshAfterRerouteWithDrivingTrafficProfile() async {
        await simulateAndTestOffRoute(with: .automobileAvoidingTraffic, shouldRefresh: true)
    }

    func disabled_testRouteRefreshAfterRerouteWithCustomDrivingTrafficProfile() async {
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

    func disabled_testRouteRefreshAfterRerouteWithDrivingTrafficProfileAndCustomParameter() async {
        await simulateAndTestOffRoute(
            with: .automobileAvoidingTraffic,
            shouldRefresh: true,
            shouldUseCustomOptions: true
        )
    }

    func disabled_testRouteRefreshAfterRerouteWithCustomDrivingTrafficProfileAndCustomParameter() async {
        await simulateAndTestOffRoute(
            with: customDrivingTraffic,
            shouldRefresh: true,
            shouldUseCustomOptions: true
        )
    }

    // MARK: Helpers

    fileprivate func defaultOptions(with profile: ProfileIdentifier) -> NavigationRouteOptions {
        NavigationRouteOptions(coordinates: [origin, destiantion], profileIdentifier: profile)
    }

    fileprivate func customOptions(
        with profile: ProfileIdentifier,
        custom: String? = "customValue"
    ) -> CustomRouteOptions {
        let options = CustomRouteOptions(coordinates: [origin, destiantion], profileIdentifier: profile)
        options.custom = custom
        return options
    }

    private func simulateAndTestOnRoute(
        with profile: ProfileIdentifier,
        shouldRefresh: Bool,
        shouldUseCustomOptions: Bool = false
    ) async {
        let options = shouldUseCustomOptions ? customOptions(with: profile) : defaultOptions(with: profile)
        let routes = await NavigationRoutes.mock(options: options, fileName: "profile-route-original")
        let expectation = await refreshExpectation(shouldRefresh: shouldRefresh)

        let tripSession = await navigationProvider.tripSession()
        await tripSession.startActiveGuidance(with: routes, startLegIndex: 0)

        let locations = routes.mainRoute.route.simulationOnRouteLocations

        for await location in createAsyncStream(from: locations) {
            await locationPublisher.send(location)
        }

        await fulfillment(of: [expectation], timeout: defaultDelay)
    }

    private func simulateAndTestOffRoute(
        with profile: ProfileIdentifier,
        shouldRefresh: Bool,
        shouldUseCustomOptions: Bool = false
    ) async {
        let options = shouldUseCustomOptions ? customOptions(with: profile) : defaultOptions(with: profile)
        let routes = await NavigationRoutes.mock(options: options, fileName: "profile-route-reroute")

        let tripSession = await navigationProvider.tripSession()
        await tripSession.startActiveGuidance(with: routes, startLegIndex: 0)
        let rerouteRoutes = await NavigationRoutes.mock(options: options, fileName: "profile-route-original")
        stubRerouteResponse("profile-route-original", shouldUseCustomOptions: shouldUseCustomOptions)

        let expectation1 = await rerouteExpectation()
        expectation1.assertForOverFulfill = false
        let locations = rerouteRoutes.mainRoute.route.simulationOnRouteLocations
        let firstLocations = Array(locations.prefix(10))
        let afterRerouteLocations = Array(locations.dropFirst(10))
        for await location in createAsyncStream(from: firstLocations) {
            await locationPublisher.send(location)
        }
        await fulfillment(of: [expectation1], timeout: defaultDelay)

        let expectation2 = await refreshExpectation(shouldRefresh: shouldRefresh)
        expectation2.assertForOverFulfill = false
        for await location in createAsyncStream(from: afterRerouteLocations) {
            await locationPublisher.send(location)
        }
        await fulfillment(of: [expectation2], timeout: defaultDelay)
    }

    private func refreshExpectation(shouldRefresh: Bool) async -> XCTestExpectation {
        let refreshExpectation = expectation(description: "Refresh expectation")
        refreshExpectation.assertForOverFulfill = false
        await navigationProvider.navigator().routeRefreshing
            .filter {
                shouldRefresh ? $0.event is RefreshingStatus.Events.Refreshed : true
            }
            .sink { _ in refreshExpectation.fulfill() }
            .store(in: &cancellables)
        refreshExpectation.isInverted = !shouldRefresh
        return refreshExpectation
    }

    private func rerouteExpectation() async -> XCTestExpectation {
        let rerouteExpectation = expectation(description: "Refresh expectation")
        await navigationProvider.navigator().rerouting
            .filter { $0.event is ReroutingStatus.Events.Fetched }
            .sink { _ in rerouteExpectation.fulfill() }
            .store(in: &cancellables)
        return rerouteExpectation
    }

    private func stubRerouteResponse(_ fileName: String, shouldUseCustomOptions: Bool) {
        let mockData = responseJsonData(bundle: .module, fileName: fileName)!
        HTTPStubs.stubRequests(
            passingTest: { request -> Bool in
                guard let url = request.url?.absoluteString,
                      url.contains("/directions/")
                else {
                    return false
                }
                return shouldUseCustomOptions ? url.contains("custom=customValue") : true
            }
        ) { _ -> HTTPStubsResponse in
            HTTPStubsResponse(
                data: mockData,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }
    }
}

extension Route {
    fileprivate var simulationOnRouteLocations: [CLLocation] {
        shape!
            .coordinates
            .map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
            .shiftedToPresent()
            .qualified()
    }

    private var simulationOffRouteLocations: [CLLocation] {
        let stepCoordiantes = legs[0].steps[0].shape!.coordinates
        let stepFirstLocation = stepCoordiantes.first!
        let stepLastLocation = stepCoordiantes.last!
        let stepDirection = stepFirstLocation.direction(to: stepLastLocation)

        let offRouteCoordiantes = [20, 30, 40].map { stepLastLocation.coordinate(at: $0, facing: stepDirection) }
        let coordinates = stepCoordiantes + offRouteCoordiantes
        return coordinates
            .map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
            .shiftedToPresent()
            .qualified()
    }
}

extension NavigationRoutes {
    fileprivate static func mock(options: RouteOptions, fileName: String) async -> NavigationRoutes {
        let response = RouteResponse.mock(bundle: .module, options: options, fileName: fileName)!
        return await NavigationRoutes.mock(routeResponse: response)!
    }
}

func createAsyncStream<Element>(from collection: some Collection<Element>) -> AsyncStream<Element> {
    var iterator = collection.makeIterator()

    return AsyncStream {
        guard let nextElement = iterator.next() else { return nil }
        if #available(iOS 16.0, *) {
            try? await Task.sleep(for: Duration.milliseconds(200))
        }

        return nextElement
    }
}
