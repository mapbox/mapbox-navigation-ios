import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation
@testable import MapboxCoreNavigation


class TurnArrowTests: FBSnapshotTestCase {
    
    let route = Fixture.route(from: "route-with-straight-roundabout", waypoints: [Waypoint(coordinate: CLLocationCoordinate2D(latitude: 59.215, longitude: 17.6334)), Waypoint(coordinate: CLLocationCoordinate2D(latitude: 59.2164, longitude: 17.6353))])
    
    var steps: [RouteStep]!
    
    override func setUp() {
        super.setUp()
        let routeController = RouteController(along: route, directions: directions)
        steps = routeController.routeProgress.currentLeg.steps
        
        route.accessToken = bogusToken
        recordMode = false
        isDeviceAgnostic = true
    }
    
    func testStraightRoundabout() {
        let turnArrowView = TurnArrowView(frame: CGRect(origin: .zero, size: CGSize(width: 50, height: 50)))
        turnArrowView.backgroundColor = .white
        let stepWithStraightRoundabout = steps[1]
        turnArrowView.step = stepWithStraightRoundabout
        FBSnapshotVerifyView(turnArrowView)
    }
}

