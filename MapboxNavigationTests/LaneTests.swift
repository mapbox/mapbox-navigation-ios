import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation
@testable import MapboxCoreNavigation


class LaneTests: FBSnapshotTestCase {

    let route = Fixture.route(from: "route-for-lane-testing", waypoints: [Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165)), Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))])
    
    var steps: [RouteStep]!
    
    override func setUp() {
        super.setUp()
        let routeController = RouteController(along: route, directions: directions)
        steps = routeController.routeProgress.currentLeg.steps
        
        route.accessToken = bogusToken
        recordMode = false
        isDeviceAgnostic = true
    }
    
    func assertLanes(step: RouteStep) {
        let rect = CGRect(origin: .zero, size: .iPhone6Plus)
        let navigationView = NavigationView(frame: rect)
        
        navigationView.lanesView.backgroundColor = .white
        navigationView.lanesView.updateLaneViews(step: step, durationRemaining: 20)
        navigationView.lanesView.isHidden = false
        
        FBSnapshotVerifyView(navigationView.lanesView)
    }
    
    func testRightRight() {
        assertLanes(step: steps[0])
    }
    
    func testRightNone() {
        assertLanes(step: steps[1])
    }
}
