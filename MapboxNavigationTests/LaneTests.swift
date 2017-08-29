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
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteMapViewController") as! RouteMapViewController
        XCTAssert(controller.view != nil)
        
        controller.updateLaneViews(step: step, alertLevel: .high)
        controller.showLaneViews(animated: false)
        
        FBSnapshotVerifyView(controller.laneViewsContainerView)
    }
    
    func testRightRight() {
        assertLanes(step: steps[0])
    }
    
    func testRightNone() {
        assertLanes(step: steps[1])
    }
    
    func storyboard() -> UIStoryboard {
        return UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
    }
}
