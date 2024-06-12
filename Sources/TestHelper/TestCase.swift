import Combine
import CoreLocation
import MapboxCommon
import MapboxDirections
@testable import MapboxNavigationCore
import XCTest

/// Base Mapbox XCTestCase class with common setup logic
open class TestCase: XCTestCase {
    public var navigationProvider: MapboxNavigationProvider!
    public var billingServiceMock: BillingServiceMock!
    public var coreConfig: CoreConfig!
    public var locationPublisher: CurrentValueSubject<CLLocation, Never>!
    public var eventsManagerSpy: NavigationTelemetryManagerSpy!

    /// Inidicates whether one time initialization completed in ``initializeIfNeeded`` method.
    private static var isInitializationCompleted: Bool = false

    override open class func setUp() {
        super.setUp()
        Credentials.injectSharedToken()
        initializeIfNeeded()
    }

    @MainActor
    override open func setUp() async throws {
        try? await super.setUp()

        billingServiceMock = .init()
        let billingHandler = BillingHandler.__createMockedHandler(with: billingServiceMock)
        let credentials = NavigationCoreApiConfiguration(accessToken: .mockedAccessToken)
        coreConfig = CoreConfig(credentials: credentials)
        coreConfig.__customBillingHandler = BillingHandlerProvider(billingHandler)
        let location = CLLocation(latitude: 9.519172, longitude: 47.210823)
        locationPublisher = .init(location)
        coreConfig
            .locationSource = .custom(.spyLocationManager(locationPublisher: locationPublisher.eraseToAnyPublisher()))
        eventsManagerSpy = NavigationTelemetryManagerSpy()
        eventsManagerSpy.userInfo = ["key": "value"]
        let eventsManager = NavigationEventsManager(navNativeEventsManager: eventsManagerSpy)
        coreConfig.__customEventsManager = .init(eventsManager)
        navigationProvider = MapboxNavigationProvider(coreConfig: coreConfig)
    }

    @MainActor
    override open func tearDown() {
        navigationProvider = nil
        super.tearDown()
    }

    override open class func tearDown() {
        Credentials.clearInjectSharedToken()
        super.tearDown()
    }

    /// Prepares tests for execution. Should be called once before any test runs.
    private static func initializeIfNeeded() {
        guard !isInitializationCompleted else { return }
        isInitializationCompleted = true

        UserDefaults.standard.set("Location Usage Description", forKey: "NSLocationWhenInUseUsageDescription")
        UserDefaults.standard.set("Location Usage Description", forKey: "NSLocationAlwaysAndWhenInUseUsageDescription")
    }
}
