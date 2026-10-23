import Combine
import CoreLocation
import MapboxCommon
import MapboxDirections
@_spi(Internal) import MapboxMaps
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
        resolveDefaultStylesOffline()
        HttpServiceFactory.setHttpServiceInterceptorForInterceptor(StyleRequestInterceptor())
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
        coreConfig.locationSource = .custom(
            .spyLocationManager(locationPublisher: locationPublisher.eraseToAnyPublisher())
        )
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
        MapStyle._overrides = [:]
        HttpServiceFactory.setHttpServiceInterceptorForInterceptor(nil)
        super.tearDown()
    }

    /// Lets style requests reach the network layer again, for a suite that asserts on the request
    /// rather than on the style.
    public static func restoreLiveStyleRequests() {
        MapStyle._overrides = [:]
        HttpServiceFactory.setHttpServiceInterceptorForInterceptor(nil)
    }

    /// Resolve the styles a `MapView` loads by default to an empty local style, so no style
    /// request is ever issued.
    private static func resolveDefaultStylesOffline() {
        let implicitlyLoadedStyleURIs: [StyleURI] = [
            .standard,
            .standardSatellite,
            // MapboxNavigationUIKit's navigationMapStyleUrl and its satellite counterpart,
            // by raw value so this stays character-identical to the other copy.
            StyleURI(rawValue: "mapbox://styles/mapbox-dash/standard-navigation")!,
            StyleURI(rawValue: "mapbox://styles/mapbox-dash/standard-satellite-navigation")!,
        ]
        var overrides: [StyleURI: MapStyle] = [:]
        for uri in implicitlyLoadedStyleURIs {
            overrides[uri] = .empty
        }
        MapStyle._overrides = overrides
    }

    /// Prepares tests for execution. Should be called once before any test runs.
    private static func initializeIfNeeded() {
        guard !isInitializationCompleted else { return }
        isInitializationCompleted = true

        UserDefaults.standard.set("Location Usage Description", forKey: "NSLocationWhenInUseUsageDescription")
        UserDefaults.standard.set("Location Usage Description", forKey: "NSLocationAlwaysAndWhenInUseUsageDescription")
    }
}
