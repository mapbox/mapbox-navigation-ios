import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

let bogusToken = "pk.feedCafeDeadBeefBadeBede"
let directions = Directions(accessToken: bogusToken)


class LaneTests: FBSnapshotTestCase {

    let route = Fixture.route(from: "route-for-lane-testing", waypoints: [Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165)), Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))])
    
    var steps: [RouteStep]!
    var routeProgress: RouteProgress!
    
    override func setUp() {
        super.setUp()
        recordMode = false
        isDeviceAgnostic = true

        route.accessToken = bogusToken
        let routeController = RouteController(along: route, directions: directions)

        steps = routeController.routeProgress.currentLeg.steps
        routeProgress = routeController.routeProgress
    }
    
    func assertLanes(step: RouteStep) {
        let rect = CGRect(origin: .zero, size: .iPhone6Plus)
        let navigationView = NavigationView(frame: rect)
        
        navigationView.lanesView.update(for: routeProgress.currentLegProgress)
        navigationView.lanesView.show(animated: false)
        
        FBSnapshotVerifyView(navigationView.lanesView)
    }
    
    func testRightRight() {
        assertLanes(step: steps[0])
    }
    
    func testRightNone() {
        assertLanes(step: steps[1])
    }
    
    func testSlightRight() {
        let view = LaneView(frame: CGRect(origin: .zero, size: CGSize(width: 30, height: 30)))
        view.backgroundColor = .white
        view.lane = Lane(indications: [.slightRight])
        view.maneuverDirection = .slightRight
        view.isValid = true
        FBSnapshotVerifyView(view, suffixes: ["_64"])
    }
}
