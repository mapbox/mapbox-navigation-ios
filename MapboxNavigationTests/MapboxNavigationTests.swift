import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

let response = Fixture.JSONFromFileNamed(name: "route-with-lanes")
let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String : Any]
let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
let bogusToken = "pk.feedCafeDeadBeefBadeBede"
let directions = Directions(accessToken: bogusToken)
let route = Route(json: jsonRoute, waypoints: [waypoint1, waypoint2], routeOptions: RouteOptions(waypoints: [waypoint1, waypoint2]))

class MapboxNavigationTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        recordMode = false
        isDeviceAgnostic = true
    }

    func storyboard() -> UIStoryboard {
        return UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
    }

    func testLanes() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteMapViewController") as! RouteMapViewController
        XCTAssert(controller.view != nil)

        route.accessToken = bogusToken
        let routeController = RouteController(along: route, directions: directions)
        routeController.advanceStepIndex(to: 7)
        controller.lanesView.update(for: routeController.routeProgress.currentLegProgress)
        controller.lanesView.show()

        FBSnapshotVerifyView(controller.lanesView)
    }
}
