import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative
@testable import MapboxNavigationUIKit
@testable import TestHelper
import XCTest

final class TunnelAuthorityTests: XCTestCase {
    var routes: NavigationRoutes!
    var routeProgress: RouteProgress!
    var tunnelAuthority: TunnelAuthority!

    let tunnelOptions: RouteOptions = {
        let from = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.892134, longitude: -77.023975))
        let to = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.880594, longitude: -77.024705))
        return NavigationRouteOptions(waypoints: [from, to])
    }()

    var tunnelRoute: Route {
        routes.mainRoute.route
    }

    var firstLocation: CLLocation {
        let firstCoordinate = tunnelRoute.shape!.coordinates.first!
        return CLLocation(coordinate: firstCoordinate)
    }

    var minimumTunnelEntranceLocation: CLLocation {
        CLLocation(
            coordinate: firstLocation.coordinate,
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            course: 0,
            speed: TunnelAuthority.Constants.minimumTunnelEntranceSpeed,
            timestamp: Date()
        )
    }

    override func setUp() async throws {
        try await super.setUp()

        tunnelAuthority = TunnelAuthority.liveValue
        routes = await Fixture.navigationRoutes(from: "routeWithTunnels_9thStreetDC", options: tunnelOptions)

        routeProgress = RouteProgress(
            navigationRoutes: routes,
            waypoints: [],
            congestionConfiguration: .default
        )
    }

    func testIsInTunnelIfOutsideTunnel() {
        let status0 = TestNavigationStatusProvider.createActiveStatus(stepIndex: 0)
        routeProgress.currentLegProgress.update(using: status0)
        let missingIntersectionTest = tunnelAuthority.isInTunnel(firstLocation, routeProgress)
        XCTAssertFalse(missingIntersectionTest, "Answer should be false. Missing intersection")
    }

    func testIsInTunnelIfSpeedIsTooLow() {
        moveToStep1()

        let secondLocation = CLLocation(
            coordinate: firstLocation.coordinate,
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            course: 0,
            speed: TunnelAuthority.Constants.minimumTunnelEntranceSpeed - 1,
            timestamp: Date()
        )

        let upcomingTunnelBadLocation = tunnelAuthority.isInTunnel(secondLocation, routeProgress)
        XCTAssertFalse(upcomingTunnelBadLocation, "Answer should be false, speed is too low.")
    }

    func testIsInTunnelIfLocationIsNotQualified() {
        // Test outside tunnel bad location due to unqualified
        moveToStep1()
        let thirdLocation = CLLocation(
            coordinate: firstLocation.coordinate,
            altitude: 0,
            horizontalAccuracy: 200,
            verticalAccuracy: 0,
            course: 0,
            speed: TunnelAuthority.Constants.minimumTunnelEntranceSpeed,
            timestamp: Date()
        )
        let upcomingTunnelBadLocationUnqualified = tunnelAuthority.isInTunnel(thirdLocation, routeProgress)
        XCTAssertFalse(upcomingTunnelBadLocationUnqualified, "Answer should be false, location is not qualified")
    }

    func testIsInTunnelIfDistanceToIntersectionIsUnset() {
        // Outside tunnel when speed it too low
        moveToStep1()
        let upcomingTunnelBadDistance = tunnelAuthority.isInTunnel(minimumTunnelEntranceLocation, routeProgress)
        XCTAssertFalse(upcomingTunnelBadDistance, "Answer should be false, distance to intersection is unset")
    }

    func testIsInTunnelIfOutsideEntranceRadius() {
        // Waiting outside tunnel
        moveToStep1()
        routeProgress.currentLegProgress.currentStepProgress.userDistanceToUpcomingIntersection = TunnelAuthority
            .Constants.tunnelEntranceRadius + 1
        let upcomingTunnelOutsideEntranceRadius = tunnelAuthority.isInTunnel(
            minimumTunnelEntranceLocation,
            routeProgress
        )
        XCTAssertFalse(upcomingTunnelOutsideEntranceRadius, "Answer should be false, outside entrance radius")
    }

    func testIsInTunnelIfInsideEntranceRadius() {
        moveToStep1()
        routeProgress.currentLegProgress.currentStepProgress.userDistanceToUpcomingIntersection = nil

        // Entering tunnel
        routeProgress.currentLegProgress.currentStepProgress.userDistanceToUpcomingIntersection = TunnelAuthority
            .Constants.tunnelEntranceRadius - 1
        let upcomingTunnelInsideEntranceRadius = tunnelAuthority.isInTunnel(
            minimumTunnelEntranceLocation,
            routeProgress
        )
        XCTAssertTrue(upcomingTunnelInsideEntranceRadius, "Answer should be true, inside entrance radius")
    }

    func testIsInTunnelIfIntersectionOutletIsTunnel() {
        moveToStep1()
        routeProgress.currentLegProgress.currentStepProgress.userDistanceToUpcomingIntersection = nil

        // Progressing through tunnel

        let statusIntersection1 = TestNavigationStatusProvider.createActiveStatus(intersectionIndex: 1)
        routeProgress.currentLegProgress.currentStepProgress.update(using: statusIntersection1)
        let currentTunnelProgressing = tunnelAuthority.isInTunnel(minimumTunnelEntranceLocation, routeProgress)
        XCTAssertTrue(currentTunnelProgressing, "Answer should be true, current intersection outlet is tunnel")
    }

    func testIsInTunnelIfExitingTunnel() {
        moveToStep1()
        // Exiting tunnel
        let statusIntersection2 = TestNavigationStatusProvider.createActiveStatus(intersectionIndex: 2)
        routeProgress.currentLegProgress.currentStepProgress.update(using: statusIntersection2)
        let exitedTunnel = tunnelAuthority.isInTunnel(minimumTunnelEntranceLocation, routeProgress)
        XCTAssertFalse(exitedTunnel, "Answer should be false, exited tunnel")
    }

    func testIsInTunnelIfBetweenTwoTunnels() {
        moveToStep1()
        // Between two tunnels with a short surface road
        routeProgress.currentLegProgress.currentStepProgress.userDistanceToUpcomingIntersection = TunnelAuthority
            .Constants.tunnelEntranceRadius + 1
        let statusIntersection4 = TestNavigationStatusProvider.createActiveStatus(intersectionIndex: 4)
        routeProgress.currentLegProgress.currentStepProgress.update(using: statusIntersection4)
        let betweenTunnels = tunnelAuthority.isInTunnel(minimumTunnelEntranceLocation, routeProgress)
        XCTAssertTrue(betweenTunnels, "Answer should be true, we are between two tunnels")
    }

    private func moveToStep1() {
        let status1 = TestNavigationStatusProvider.createActiveStatus(stepIndex: 1)
        routeProgress.currentLegProgress.update(using: status1)
        routeProgress.currentLegProgress.currentStepProgress
            .intersectionsIncludingUpcomingManeuverIntersection = routeProgress.currentLegProgress.currentStepProgress
            .step.intersections

        let statusIntersection0 = TestNavigationStatusProvider.createActiveStatus(intersectionIndex: 0)
        routeProgress.currentLegProgress.currentStepProgress.update(using: statusIntersection0)
    }
}
