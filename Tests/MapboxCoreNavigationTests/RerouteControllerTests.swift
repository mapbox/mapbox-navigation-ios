import MapboxDirections
import MapboxNavigationNative
import XCTest
@testable import TestHelper
@testable import MapboxCoreNavigation

final class RerouteControllerTests: TestCase {
    class DelegateSpy: ReroutingControllerDelegate {
        var onWantsSwitchToAlternative: ((RouteResponse, Int, RouteOptions, RouterOrigin) -> Void)?
        var onDidDetectReroute: (() -> Bool)?
        var onDidRecieveReroute: ((RouteResponse, RouteOptions, RouterOrigin) -> Void)?
        var onDidCancelReroute: (() -> Void)?
        var onDidFailReroute: ((DirectionsError) -> Void)?
        var onWillModifyOptions: ((RouteOptions) -> RouteOptions)?

        func rerouteControllerWantsSwitchToAlternative(_ rerouteController: MapboxCoreNavigation.RerouteController,
                                                       response: RouteResponse,
                                                       routeIndex: Int,
                                                       options: RouteOptions,
                                                       routeOrigin: RouterOrigin) {
            onWantsSwitchToAlternative?(response, routeIndex, options, routeOrigin)
        }

        func rerouteControllerDidDetectReroute(_ rerouteController: MapboxCoreNavigation.RerouteController) -> Bool {
            return onDidDetectReroute?() ?? true
        }

        func rerouteControllerDidRecieveReroute(_ rerouteController: MapboxCoreNavigation.RerouteController,
                                                response: RouteResponse,
                                                options: RouteOptions,
                                                routeOrigin: RouterOrigin) {
            onDidRecieveReroute?(response, options, routeOrigin)
        }

        func rerouteControllerDidCancelReroute(_ rerouteController: MapboxCoreNavigation.RerouteController) {
            onDidCancelReroute?()
        }

        func rerouteControllerDidFailToReroute(_ rerouteController: MapboxCoreNavigation.RerouteController,
                                               with error: DirectionsError) {
            onDidFailReroute?(error)
        }

        func rerouteControllerWillModify(options: RouteOptions) -> RouteOptions {
            onWillModifyOptions?(options) ?? options
        }

    }

    private var routeOptions: RouteOptions!
    private var route: RouteInterface!

    private var navigatorSpy: NativeNavigatorSpy!
    private var configHandle: ConfigHandle!
    private var rerouteDetector: RerouteDetectorSpy!
    private var customRoutingProvider: RoutingProviderSpy!

    private var delegate: DelegateSpy!
    private var rerouteController: RerouteController!

    override func setUp() {
        super.setUp()

        route = TestRouteProvider.createRoute()
        routeOptions = RouteOptions(url: URL(string: route.getRequestUri())!)

        rerouteDetector = .init()
        configHandle = NativeHandlersFactory.configHandle(by: ConfigFactorySpy.self)
        navigatorSpy = .init()
        navigatorSpy.rerouteDetector = rerouteDetector
        customRoutingProvider = .init()
        delegate = .init()

        rerouteController = .init(navigatorSpy, config: configHandle)
        rerouteController.delegate = delegate
    }

    func testReturnInitialManeuverAvoidanceRadius() {
        XCTAssertEqual(rerouteController.initialManeuverAvoidanceRadius, RerouteController.DefaultManeuverAvoidanceRadius)

        rerouteController.initialManeuverAvoidanceRadius = 4
        XCTAssertEqual(rerouteController.initialManeuverAvoidanceRadius, 4)
    }

    func testSetCustomRoutingProvider() {
        let customRoutingProvider = RoutingProviderSpy()
        rerouteController.customRoutingProvider = customRoutingProvider
        XCTAssertTrue(navigatorSpy.passedRerouteController === rerouteController)
    }

    func testReturnUserIsOnRoute() {
        XCTAssertTrue(rerouteController.userIsOnRoute())

        rerouteDetector.returnedIsReroute = true
        XCTAssertFalse(rerouteController.userIsOnRoute())
    }

    func testForceReroute() {
        rerouteController.forceReroute()
        XCTAssertTrue(rerouteDetector.forceRerouteCalled)
    }

    func testReset() {
        rerouteController.reroutesProactively = false
        rerouteController.customRoutingProvider = customRoutingProvider

        rerouteController.resetToDefaultSettings()
        XCTAssertTrue(rerouteController.reroutesProactively)
        XCTAssertNil(rerouteController.customRoutingProvider)
    }

    func testHandleOnSwitchToAlternative() {
        let expectation = XCTestExpectation(description: "Call delegate")
        delegate.onWantsSwitchToAlternative = { (response, routeIndex, options, routeOrigin) in
            XCTAssertEqual(routeIndex, Int(self.route.getRouteIndex()))
            XCTAssertEqual(options, self.routeOptions)
            XCTAssertEqual(routeOrigin, self.route.getRouterOrigin())
            expectation.fulfill()
        }
        rerouteController.onSwitchToAlternative(forRoute: route)
        wait(for: [expectation], timeout: 1)
    }

    func testHandleOnRerouteDetected() {
        let expectation = XCTestExpectation(description: "Call delegate")
        delegate.onDidDetectReroute = {
            expectation.fulfill()
            return false
        }
        XCTAssertFalse(rerouteController.onRerouteDetected(forRouteRequest: "request"))

        rerouteController.delegate = nil
        XCTAssertTrue(rerouteController.onRerouteDetected(forRouteRequest: "request"))
        wait(for: [expectation], timeout: 1)
    }

}
