import _MapboxNavigationTestHelpers
import CoreLocation
import Foundation
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private
import Turf
import XCTest

class RouteProgressTests: BaseTestCase {
    var routes: NavigationRoutes!
    var twoLegsRoutes: NavigationRoutes!
    var routeProgress: RouteProgress!

    override func setUp() async throws {
        try? await super.setUp()

        routes = await .mock()
        let mainRoute = Route.mock(legs: [.mock(), .mock(), .mock()])
        let navigationRoute = NavigationRoute.mock(route: mainRoute)
        twoLegsRoutes = await NavigationRoutes.mock(mainRoute: navigationRoute)

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

    func testSetLegIndex() {
        let oneLegRouteProgress = RouteProgress(
            navigationRoutes: routes,
            waypoints: [],
            congestionConfiguration: .default,
            legIndex: 1
        )
        XCTAssertEqual(oneLegRouteProgress.legIndex, 0, "Should not be greater than legs count")

        let twoLegsRouteProgress = RouteProgress(
            navigationRoutes: twoLegsRoutes,
            waypoints: [],
            congestionConfiguration: .default,
            legIndex: 1
        )
        XCTAssertEqual(twoLegsRouteProgress.legIndex, 1)

        let incorrectIndexRouteProgress = RouteProgress(
            navigationRoutes: routes,
            waypoints: [],
            congestionConfiguration: .default,
            legIndex: -1
        )
        XCTAssertEqual(incorrectIndexRouteProgress.legIndex, 0)
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

    func testRefreshingRouteIfMainRouteRefreshed() async {
        let refreshedSteps: [RouteStep] = [
            .mock(maneuverType: .arrive),
        ]
        let refreshedLeg = RouteLeg.mock(steps: refreshedSteps)
        let refreshedDirectionsRoute = Route.mock(legs: [refreshedLeg])
        let refreshedRoutes = await NavigationRoutes.mock(
            mainRoute: .mock(route: refreshedDirectionsRoute),
            alternativeRoutes: [.mock()]
        )
        let refreshedProgress = routeProgress.refreshingRoute(
            with: refreshedRoutes,
            refreshedMainLegIndex: 0,
            congestionConfiguration: .default
        )
        XCTAssertEqual(refreshedProgress.navigationRoutes, refreshedRoutes)
        XCTAssertEqual(refreshedProgress.currentLeg, refreshedLeg)
        XCTAssertEqual(refreshedProgress.currentLegProgress.leg, refreshedLeg)
    }

    func testRefreshingRouteIfAlternativeRouteRefreshed() async {
        let refreshedSteps: [RouteStep] = [
            .mock(maneuverType: .depart),
            .mock(maneuverType: .useLane),
        ]
        let refreshedLeg = RouteLeg.mock(steps: refreshedSteps)
        let refreshedDirectionsRoute = Route.mock(legs: [refreshedLeg])
        let refreshedAlternative = AlternativeRoute.mock(
            mainRoute: routes.mainRoute.route,
            alternativeRoute: refreshedDirectionsRoute
        )
        let refreshedRoutes = await NavigationRoutes.mock(
            mainRoute: twoLegsRoutes.mainRoute,
            alternativeRoutes: [refreshedAlternative]
        )
        routeProgress = RouteProgress(
            navigationRoutes: twoLegsRoutes,
            waypoints: [],
            congestionConfiguration: .default,
            legIndex: 1
        )
        let refreshedProgress = routeProgress.refreshingRoute(
            with: refreshedRoutes,
            refreshedMainLegIndex: nil,
            congestionConfiguration: .default
        )
        XCTAssertEqual(refreshedProgress.navigationRoutes, refreshedRoutes)
        XCTAssertEqual(refreshedProgress.currentLeg, twoLegsRoutes.mainRoute.route.legs[1])
        XCTAssertEqual(refreshedProgress.currentLegProgress.leg, twoLegsRoutes.mainRoute.route.legs[1])
    }
}
