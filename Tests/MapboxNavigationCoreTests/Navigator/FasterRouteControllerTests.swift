import _MapboxNavigationTestHelpers
import Combine
import CoreLocation
import Foundation
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private
import XCTest

@available(iOS 16.0, *)
private final class RoutingProviderMock: RoutingProvider, @unchecked Sendable {
    var delay: Duration = .milliseconds(50)
    var result: NavigationRoutes?

    private let lock = NSLock()
    private var _calculateRoutesCallCount = 0
    var calculateRoutesCallCount: Int {
        lock.withLock { _calculateRoutesCallCount }
    }

    func calculateRoutes(options: RouteOptions) -> FetchTask {
        lock.withLock { _calculateRoutesCallCount += 1 }
        let delay = delay
        let result = result
        return Task {
            try await Task.sleep(for: delay)
            if let result {
                return result
            }
            throw NSError(domain: "RoutingProviderMock", code: -1)
        }
    }

    func calculateRoutes(options: MatchOptions) -> FetchTask {
        calculateRoutes(options: RouteOptions(coordinates: []))
    }
}

// @available(iOS 16.0, *)
// final class FasterRouteControllerTests: XCTestCase {
//    private var routingProvider: RoutingProviderMock!
//    private var routes: NavigationRoutes!
//    private var newRoutes: NavigationRoutes!
//    private var routeProgress: RouteProgress!
//    private let location = CLLocation(latitude: 37.33, longitude: -122.03)
//    private let iterations = 1000
//
//    override func setUp() async throws {
//        try await super.setUp()
//        routingProvider = RoutingProviderMock()
//        routes = await NavigationRoutes.mock()
//        newRoutes = await NavigationRoutes.mock()
//        routeProgress = makeRouteProgress(navigationRoutes: routes)
//    }
//
//    override func tearDown() async throws {
//        routingProvider = nil
//        try await super.tearDown()
//    }
//
//    /// Crash #1: `objc_retain` on freed `NavigationRoute` — cooperative pool reads
//    /// `navigationRoute` while another thread sets it to `nil`.
//    func testConcurrentNavigationRouteNillingCrashesOnRetainIfRouteRequestSuccess() {
//        let controller = makeController()
//        controller.navigationRoute = routes.mainRoute
//        controller.currentLocation = location
//        routingProvider.result = newRoutes
//
//        DispatchQueue.concurrentPerform(iterations: iterations) { i in
//            if i % 3 == 0 {
//                controller.checkForFasterRoute(from: self.routeProgress)
//            } else if i % 3 == 1 {
//                controller.navigationRoute = self.routes.mainRoute
//            } else {
//                controller.navigationRoute = nil
//            }
//        }
//    }
//
//    /// Crash #1: `objc_retain` on freed `NavigationRoute` — cooperative pool reads
//    /// `navigationRoute` while another thread sets it to `nil`.
//    func testConcurrentNavigationRouteNillingCrashesOnRetainIfRouteRequestError() {
//        let controller = makeController()
//        controller.navigationRoute = routes.mainRoute
//        controller.currentLocation = location
//
//        DispatchQueue.concurrentPerform(iterations: iterations) { i in
//            if i % 3 == 0 {
//                controller.checkForFasterRoute(from: self.routeProgress)
//            } else if i % 3 == 1 {
//                controller.navigationRoute = self.routes.mainRoute
//            } else {
//                controller.navigationRoute = nil
//            }
//        }
//    }
//
//    /// Crash #2: `NSInvalidArgumentException` — message forwarded to deallocated
//    /// `NavigationRoute` whose class metadata is already gone.
//    func testConcurrentPropertyMutationCrashesOnForwarding() {
//        let controller = makeController()
//        controller.navigationRoute = routes.mainRoute
//        controller.currentLocation = location
//
//        DispatchQueue.concurrentPerform(iterations: iterations) { i in
//            switch i % 5 {
//            case 0:
//                controller.checkForFasterRoute(from: self.routeProgress)
//            case 1:
//                controller.navigationRoute = self.routes.mainRoute
//            case 2:
//                controller.navigationRoute = nil
//            case 3:
//                controller.currentLocation = self.location
//            default:
//                controller.currentLocation = nil
//            }
//        }
//    }
//
//    /// Full reproduction of both crashes: mirrors `subscribeFasterRouteController()` in
//    /// `MapboxNavigator` where four Combine sinks fire concurrently writing `navigationRoute`,
//    /// `currentLocation`, `isRerouting` while `checkForFasterRoute` spawns cooperative Tasks.
//    func testSubscriberPatternConcurrentAccessCrashes() {
//        let controller = makeController()
//        controller.navigationRoute = routes.mainRoute
//        controller.currentLocation = location
//
//        DispatchQueue.concurrentPerform(iterations: iterations) { i in
//            switch i % 7 {
//            case 0, 1:
//                controller.checkForFasterRoute(from: self.routeProgress)
//            case 2:
//                controller.navigationRoute = self.routes.mainRoute
//            case 3:
//                controller.navigationRoute = nil
//            case 4:
//                controller.currentLocation = CLLocation(
//                    latitude: 37.33 + Double(i) * 0.0001,
//                    longitude: -122.03
//                )
//            case 5:
//                controller.currentLocation = nil
//            default:
//                controller.isRerouting = (i % 2 == 0)
//            }
//        }
//    }
//
//    // MARK: - Helpers
//
//    private func makeController() -> FasterRouteController {
//        let config = FasterRouteDetectionConfig(
//            proactiveReroutingInterval: 0,
//            minimumRouteDurationRemaining: 0,
//            minimumManeuverOffset: 0
//        )
//        return FasterRouteController(
//            configuration: .init(
//                settings: config,
//                initialManeuverAvoidanceRadius: 10,
//                routingProvider: routingProvider
//            )
//        )
//    }
//
//    private func makeRouteProgress(navigationRoutes: NavigationRoutes) -> RouteProgress {
//        var progress = RouteProgress.mock(
//            navigationRoutes: navigationRoutes,
//            waypoints: [],
//            congestionConfiguration: .default
//        )
//        let status = NavigationStatus.mock(
//            activeGuidanceInfo: .mock(
//                routeProgress: .mock(remainingDuration: 1000),
//                legProgress: .mock(remainingDuration: 1000),
//                stepProgress: .mock(remainingDuration: 200)
//            ),
//            stepIndex: 0
//        )
//        progress.update(using: status)
//        return progress
//    }
// }
