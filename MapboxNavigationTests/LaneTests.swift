import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

let bogusToken = "pk.feedCafeDeadBeefBadeBede"
let directions = Directions(accessToken: bogusToken)


class LaneTests: FBSnapshotTestCase {

    let route = Fixture.route(from: "route-for-lane-testing", waypoints: [Waypoint(coordinate: CLLocationCoordinate2D(latitude: 39.132063, longitude: -84.531074)), Waypoint(coordinate: CLLocationCoordinate2D(latitude: 39.138953, longitude: -84.532934))])
    
    var steps: [RouteStep]!
    var routeProgress: RouteProgress!
    var routeController: RouteController!
    let routerDataSource = RouteControllerDataSourceFake()
    
    override func setUp() {
        super.setUp()
        recordMode = false
        isDeviceAgnostic = true

        route.accessToken = bogusToken
        routeController = RouteController(along: route, directions: directions, dataSource: routerDataSource)

        steps = routeController.routeProgress.currentLeg.steps
        routeProgress = routeController.routeProgress
    }
    
    func assertLanes(stepIndex: Array<RouteStep>.Index) {
        let rect = CGRect(origin: .zero, size: .iPhone6Plus)
        let navigationView = NavigationView(frame: rect)
        
        routeController.advanceStepIndex(to: stepIndex)
        
        navigationView.lanesView.update(for: routeController.routeProgress.currentLegProgress.currentStepProgress.currentVisualInstruction)
        navigationView.lanesView.show(animated: false)
        
        FBSnapshotVerifyView(navigationView.lanesView)
    }
    
    func testStraightRight() {
        assertLanes(stepIndex: 0)
    }
    
    func testRightRight() {
        assertLanes(stepIndex: 1)
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
