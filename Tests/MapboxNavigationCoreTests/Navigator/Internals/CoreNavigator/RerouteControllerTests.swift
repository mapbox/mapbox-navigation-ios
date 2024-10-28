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
    var didRecieveRerouteCalled = false
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

    func rerouteControllerDidRecieveReroute(_ rerouteController: RerouteController, routesData: any RoutesData) {
        didRecieveRerouteCalled = true
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

    @MainActor
    override func setUp() {
        super.setUp()

        delegate = ReroutingControllerDelegateSpy()
        navNavigator = NativeNavigatorSpy()
        navigator = NavigationNativeNavigator(navigator: navNavigator, locale: .current)
        configuration = RerouteController.Configuration(
            credentials: .mock(),
            navigator: navigator,
            configHandle: .mock(),
            rerouteConfig: .init(),
            initialManeuverAvoidanceRadius: 45.0
        )
        rerouteController = rerouteController(with: true)
    }

    @MainActor
    private func rerouteController(with detectsReroute: Bool) -> RerouteController {
        super.setUp()

        let configuration = RerouteController.Configuration(
            credentials: .mock(),
            navigator: navigator,
            configHandle: .mock(),
            rerouteConfig: RerouteConfig(detectsReroute: detectsReroute),
            initialManeuverAvoidanceRadius: 45.0
        )
        let rerouteController = RerouteController(configuration: configuration)
        rerouteController.delegate = delegate
        return rerouteController
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
        let rerouteController = rerouteController(with: false)
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
        let rerouteController = rerouteController(with: false)
        rerouteController.onSwitchToAlternative(forRoute: RouteInterfaceMock(), legIndex: 1)
        XCTAssertTrue(delegate.wantsSwitchToAlternativeCalled)
    }
}
