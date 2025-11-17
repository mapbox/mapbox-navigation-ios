@testable import _MapboxNavigationTestHelpers
import Combine
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private
import OHHTTPStubs
import XCTest

class BaseIntegrationTest: BaseTestCase {
    let customDrivingTraffic = ProfileIdentifier(rawValue: "custom/driving-traffic")
    let customDriving = ProfileIdentifier(rawValue: "custom/driving")
    let defaultDelay: TimeInterval = 5
    let locationUpdateDelay = 50

    var coreConfig: CoreConfig!
    var navigationProvider: MapboxNavigationProvider!
    var billingServiceMock: BillingServiceMock!
    var locationPublisher: CurrentValueSubject<CLLocation, Never>!
    var cancellables: Set<AnyCancellable>!

    @MainActor
    override func setUp() {
        super.setUp()

        cancellables = []
        billingServiceMock = .init()
        let billingHandler = BillingHandler.__createMockedHandler(with: billingServiceMock)
        let credentials = NavigationCoreApiConfiguration(accessToken: .mockedAccessToken)
        coreConfig = CoreConfig(
            credentials: credentials,
            routingConfig: .init(routeRefreshPeriod: 1)
        )
        let origin = CLLocationCoordinate2D(latitude: 40.76050975068355, longitude: -73.98778274913309)
        let location = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        locationPublisher = .init(location)
        coreConfig.__customBillingHandler = BillingHandlerProvider(billingHandler)
        coreConfig.locationSource = .custom(.mock(locationPublisher.eraseToAnyPublisher()))
        navigationProvider = MapboxNavigationProvider(coreConfig: coreConfig)
    }

    @MainActor
    override func tearDown() {
        cancellables = nil
        HTTPStubs.removeAllStubs()
        navigationProvider.tripSession().setToIdle()
        navigationProvider = nil
        super.tearDown()
    }

    func simulateLocations(_ locations: [CLLocation]) async {
        for location in locations {
            locationPublisher.send(location)
            if #available(iOS 16.0, *) {
                try? await Task.sleep(for: Duration.milliseconds(locationUpdateDelay))
            }
        }
    }

    func refreshExpectation(shouldRefresh: Bool) async -> XCTestExpectation {
        let refreshExpectation = expectation(description: "Refresh expectation")
        await navigationProvider.navigator().routeRefreshing
            .filter { shouldRefresh ? $0.event is RefreshingStatus.Events.Refreshed : true }
            .sink { _ in refreshExpectation.fulfill() }
            .store(in: &cancellables)
        refreshExpectation.isInverted = !shouldRefresh
        return refreshExpectation
    }

    func rerouteExpectation() async -> XCTestExpectation {
        let rerouteExpectation = expectation(description: "Reroute expectation")
        await navigationProvider.navigator().rerouting
            .filter { $0.event is ReroutingStatus.Events.Fetched }
            .sink { _ in rerouteExpectation.fulfill() }
            .store(in: &cancellables)
        return rerouteExpectation
    }

    func trackingStatusExpectation(
        state: Session.State = .activeGuidance(.tracking)
    ) async -> XCTestExpectation {
        let trackingStatusExpectation = expectation(description: "Session state \(state) expectation")
        await navigationProvider.navigator().session
            .filter { $0.state == state }
            .first()
            .sink { _ in trackingStatusExpectation.fulfill() }
            .store(in: &cancellables)
        return trackingStatusExpectation
    }

    func stubRouteRefreshResponse(
        _ fileName: String,
        filterClosure: ((String) -> Bool)? = nil
    ) {
        let mockData = responseJsonData(bundle: .module, fileName: fileName)!
        HTTPStubs.stubRequests(
            passingTest: { request -> Bool in
                guard let url = request.url?.absoluteString,
                      url.contains("directions-refresh")
                else {
                    return false
                }
                return filterClosure?(url) ?? true
            }
        ) { _ -> HTTPStubsResponse in
            HTTPStubsResponse(
                data: mockData,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }
    }

    func stubRouteResponse(
        _ fileName: String,
        filterClosure: ((String) -> Bool)? = nil
    ) {
        let mockData = responseJsonData(bundle: .module, fileName: fileName)!
        HTTPStubs.stubRequests(
            passingTest: { request -> Bool in
                guard let url = request.url?.absoluteString,
                      url.contains("/directions/")
                else {
                    return false
                }
                return filterClosure?(url) ?? true
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
    var simulationOnRouteLocations: [CLLocation] {
        shape!
            .coordinates
            .map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
            .shiftedToPresent()
            .qualified()
    }
}

extension NavigationRoutes {
    static func mock(options: RouteOptions, fileName: String) async -> NavigationRoutes {
        let response = RouteResponse.mock(bundle: .module, options: options, fileName: fileName)!
        return await NavigationRoutes.mock(routeResponse: response)!
    }
}
