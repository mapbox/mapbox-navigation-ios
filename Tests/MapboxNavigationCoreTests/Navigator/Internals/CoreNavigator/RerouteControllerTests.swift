import _MapboxNavigationTestHelpers
@testable import MapboxNavigationCore
import MapboxNavigationNative
import XCTest

final class ReroutingControllerDelegateSpy: ReroutingControllerDelegate {
    var passedRerouteController: RerouteController?
    var passedRoute: (any RouteInterface)?
    var passedLegIndex: Int?
    var passedRoutesData: (any RoutesData)?
    var passedError: DirectionsError?

    var wantsSwitchToAlternativeCalled = false
    var didDetectRerouteCalled = false
    var didReceiveRerouteCalled = false
    var didCancelRerouteCalled = false
    var didFailToRerouteCalled = false

    func rerouteControllerWantsSwitchToAlternative(
        _ rerouteController: RerouteController,
        route: any RouteInterface,
        legIndex: Int
    ) {
        wantsSwitchToAlternativeCalled = true
        passedRerouteController = rerouteController
        passedRoute = route
        passedLegIndex = legIndex
    }

    func rerouteControllerDidDetectReroute(_ rerouteController: RerouteController) {
        didDetectRerouteCalled = true
        passedRerouteController = rerouteController
    }

    func rerouteControllerDidReceiveReroute(_ rerouteController: RerouteController, routesData: any RoutesData) {
        didReceiveRerouteCalled = true
        passedRerouteController = rerouteController
        passedRoutesData = routesData
    }

    func rerouteControllerDidCancelReroute(_ rerouteController: RerouteController) {
        didCancelRerouteCalled = true
        passedRerouteController = rerouteController
    }

    func rerouteControllerDidFailToReroute(_ rerouteController: RerouteController, with error: DirectionsError) {
        didFailToRerouteCalled = true
        passedRerouteController = rerouteController
        passedError = error
    }
}

final class RerouteControllerTests: XCTestCase {
    var rerouteController: RerouteController!
    var configuration: RerouteController.Configuration!
    var navigator: NavigationNativeNavigator!
    var navNavigator: NativeNavigatorSpy!
    var delegate: ReroutingControllerDelegateSpy!

    private var nativeRerouteController: NativeRerouteControllerSpy {
        navNavigator.rerouteController as! NativeRerouteControllerSpy
    }

    override func setUp() async throws {
        try? await super.setUp()

        delegate = ReroutingControllerDelegateSpy()
        navNavigator = NativeNavigatorSpy()
        navigator = await NavigationNativeNavigator(navigator: navNavigator, locale: .current)
        configuration = RerouteController.Configuration(
            credentials: .mock(),
            navigator: navigator,
            configHandle: .mock(),
            rerouteConfig: .init(),
            initialManeuverAvoidanceRadius: 45.0
        )
        rerouteController = await rerouteController(with: configuration)
    }

    @MainActor
    private func rerouteController(
        with configuration: RerouteController.Configuration
    ) -> RerouteController {
        let rerouteController = RerouteController(configuration: configuration)
        rerouteController.delegate = delegate
        return rerouteController
    }

    @MainActor
    private func rerouteController(
        with rerouteConfig: RerouteConfig
    ) -> RerouteController {
        let configuration = RerouteController.Configuration(
            credentials: configuration.credentials,
            navigator: configuration.navigator,
            configHandle: configuration.configHandle,
            rerouteConfig: rerouteConfig,
            initialManeuverAvoidanceRadius: configuration.initialManeuverAvoidanceRadius
        )
        return rerouteController(with: configuration)
    }

    @MainActor
    func testIsOnRouteIfNilNativeRerouteDetector() {
        navNavigator.rerouteDetector = nil
        let rerouteController = RerouteController(configuration: configuration)
        XCTAssertTrue(rerouteController.userIsOnRoute())
    }

    @MainActor
    func testIsOnRouteIfNonNilNativeRerouteDetector() {
        let rerouteDetector = navNavigator.rerouteDetector as! RerouteDetectorSpy
        let rerouteController = RerouteController(configuration: configuration)

        rerouteDetector.returnedIsReroute = false
        XCTAssertTrue(rerouteController.userIsOnRoute())

        rerouteDetector.returnedIsReroute = true
        XCTAssertFalse(rerouteController.userIsOnRoute())
    }

    @MainActor
    func testNoDidCancelRerouteCallIfRerouteDisabled() {
        let rerouteController = rerouteController(with: .init(detectsReroute: false))
        rerouteController.onRerouteCancelled()
        XCTAssertFalse(delegate.didCancelRerouteCalled)
    }

    @MainActor
    func testCallDidCancelReroute() {
        rerouteController.onRerouteCancelled()
        XCTAssertTrue(delegate.didCancelRerouteCalled)
        XCTAssertTrue(delegate.passedRerouteController === rerouteController)
    }

    @MainActor
    func testCallWantsSwitchToAlternative() {
        let route = RouteInterfaceMock()
        rerouteController.onSwitchToAlternative(forRoute: route, legIndex: 1)
        XCTAssertTrue(delegate.wantsSwitchToAlternativeCalled)
        XCTAssertTrue(delegate.passedRoute === route)
        XCTAssertEqual(delegate.passedLegIndex, 1)
    }

    @MainActor
    func testNoWantsSwitchToAlternativeCallIfRerouteDisabled() {
        let rerouteController = rerouteController(with: .init(detectsReroute: false))
        rerouteController.onSwitchToAlternative(forRoute: RouteInterfaceMock(), legIndex: 1)
        XCTAssertTrue(delegate.wantsSwitchToAlternativeCalled)
    }

    @MainActor
    func testDoesNotSetRouteOptionsAdapterIfUrlOptionsCustomizationNotSet() {
        XCTAssertFalse(nativeRerouteController.setOptionsAdapterCalled)
    }

    @MainActor
    func testSetsRouteOptionsAdapterIfUrlOptionsCustomizationSet() {
        let customization = EquatableClosure<String, String> {
            $0 + customQueryParam2
        }
        rerouteController = rerouteController(with: .init(
            urlOptionsCustomization: customization
        ))
        let url = directionsUrl + customQueryParam

        XCTAssertTrue(nativeRerouteController.setOptionsAdapterCalled)
        XCTAssertEqual(
            customization(url),
            nativeRerouteController.passedRouteOptionsAdapter?
                .modifyRouteRequestOptions(forUrl: url)
        )
    }
}

private let directionsUrl =
    "https://api.mapbox.com/directions/v5/mapbox/driving/-84.411389,39.27665;-84.412115,39.272675?alternatives=false&continue_straight=true&geometries=polyline&overview=false&steps=false&language=en_US&access_token=" +
    String.mockedAccessToken

private let customQueryParam = "&custom_param_name=custom_param_value"
private let customQueryParam2 = "&custom_param_name2=custom_param_value2"
