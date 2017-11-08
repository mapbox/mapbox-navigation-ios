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
    
    var shieldImage: UIImage {
        get {
            let bundle = Bundle(for: MapboxNavigationTests.self)
            return UIImage(named: "80px-I-280", in: bundle, compatibleWith: nil)!
        }
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        recordMode = false
        isDeviceAgnostic = true
        
        UIImage.shieldImageCache.setObject(shieldImage, forKey: "I280")
    }
    
    func storyboard() -> UIStoryboard {
        return UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
    }
    
    func testLanes() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteMapViewController") as! RouteMapViewController
        XCTAssert(controller.view != nil)
        
        route.accessToken = bogusToken
        let routeController = RouteController(along: route, directions: directions)
        let steps = routeController.routeProgress.currentLeg.steps
        let stepWithLanes = steps[8]
        controller.updateLaneViews(step: stepWithLanes, durationRemaining: 20)
        controller.showLaneViews(animated: false)
        
        FBSnapshotVerifyView(controller.laneViewsContainerView)
    }
}



extension CLLocationCoordinate2D {
    static var unionSquare: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: 37.786902, longitude: -122.407668)
    }
    
    static var goldenGatePark: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: 37.770935, longitude: -122.479346)
    }
    
    static var bernalHeights: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: 37.739912, longitude: -122.420100)
    }
}
