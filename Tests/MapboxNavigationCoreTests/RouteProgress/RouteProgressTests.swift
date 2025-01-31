import _MapboxNavigationTestHelpers
import CoreLocation
import Foundation
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative
import Turf
import XCTest

class RouteProgressTests: BaseTestCase {
    var routes: NavigationRoutes!
    var routeProgress: RouteProgress!

    override func setUp() async throws {
        try? await super.setUp()

        routes = await .mock()

        routeProgress = RouteProgress(
            navigationRoutes: routes,
            waypoints: [],
            congestionConfiguration: .default
        )
    }

    func testInitialProgressValues() {
        XCTAssertEqual(routeProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.distanceRemaining, 0)
        XCTAssertEqual(routeProgress.distanceTraveled, 0)
        XCTAssertEqual(routeProgress.durationRemaining, 0)
    }

    func testReturnDistanceTraveled() {
        let stepValue = 100.0
        let legValue = 200.0
        let routeValue = 300.0
        let status = NavigationStatus.mock(
            activeGuidanceInfo: .mock(
                routeProgress: .mock(distanceTraveled: routeValue),
                legProgress: .mock(distanceTraveled: legValue),
                stepProgress: .mock(distanceTraveled: stepValue)
            )
        )
        routeProgress.update(using: status)
        XCTAssertEqual(routeProgress.distanceTraveled, routeValue)
    }

    func testReturnFractionTraveled() {
        let stepValue = 100.0
        let legValue = 200.0
        let routeValue = 300.0
        let status = NavigationStatus.mock(
            activeGuidanceInfo: .mock(
                routeProgress: .mock(fractionTraveled: routeValue),
                legProgress: .mock(fractionTraveled: legValue),
                stepProgress: .mock(fractionTraveled: stepValue)
            )
        )
        routeProgress.update(using: status)
        XCTAssertEqual(routeProgress.fractionTraveled, routeValue)
    }

    func testReturnRemainingDuration() {
        let stepValue = 100.0
        let legValue = 200.0
        let routeValue = 300.0
        let status = NavigationStatus.mock(
            activeGuidanceInfo: .mock(
                routeProgress: .mock(remainingDuration: routeValue),
                legProgress: .mock(remainingDuration: legValue),
                stepProgress: .mock(remainingDuration: stepValue)
            )
        )
        routeProgress.update(using: status)
        XCTAssertEqual(routeProgress.durationRemaining, routeValue)
    }

    func testReturnDistanceRemaining() {
        let stepValue = 100.0
        let legValue = 200.0
        let routeValue = 300.0
        let status = NavigationStatus.mock(
            activeGuidanceInfo: .mock(
                routeProgress: .mock(remainingDistance: routeValue),
                legProgress: .mock(remainingDistance: legValue),
                stepProgress: .mock(remainingDistance: stepValue)
            )
        )
        routeProgress.update(using: status)
        XCTAssertEqual(routeProgress.distanceRemaining, routeValue)
    }

    func testNextRouteStepProgress() {
        let stepSistanceRemaining = 300.0
        let status = NavigationStatus.mock(
            activeGuidanceInfo: .mock(
                stepProgress: .mock(
                    remainingDistance: stepSistanceRemaining
                )
            ),
            stepIndex: 1
        )
        routeProgress.update(using: status)

        let step = routes.mainRoute.route.legs.first!.steps[1]
        XCTAssertEqual(routeProgress.currentLegProgress.stepIndex, 1)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.step, step)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceRemaining, stepSistanceRemaining)
    }

    func testAlternativeRoutesUpdated() async {
        let newRoutes = await NavigationRoutes.mock(
            mainRoute: routes.mainRoute,
            alternativeRoutes: [.mock()]
        )

        XCTAssertTrue(routeProgress.navigationRoutes.alternativeRoutes.isEmpty)

        routeProgress.updateAlternativeRoutes(using: newRoutes)

        XCTAssertEqual(routeProgress.navigationRoutes, newRoutes)
    }

    func testAlternativeRoutesNotUpdated() async {
        let newRoutes = await NavigationRoutes.mock(
            alternativeRoutes: [.mock()]
        )

        XCTAssertTrue(routeProgress.navigationRoutes.alternativeRoutes.isEmpty)

        routeProgress.updateAlternativeRoutes(using: newRoutes)

        XCTAssertNotEqual(routeProgress.navigationRoutes, newRoutes)
    }
}
