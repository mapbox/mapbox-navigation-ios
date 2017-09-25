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
    }
    
    func storyboard() -> UIStoryboard {
        return UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
    }
    
    func testManeuverViewMultipleLines() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        
        controller.distance = nil
        controller.turnArrowView.isEnd = true
        controller.shieldImage = shieldImage
        controller.destinationLabel.unabridgedText = "This should be multiple lines"
        controller.destinationLabel.backgroundColor = .red
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testManeuverViewSingleLine() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        
        controller.distance = 804
        controller.turnArrowView.isEnd = true
        controller.shieldImage = shieldImage
        controller.destinationLabel.unabridgedText = "Single line"
        controller.destinationLabel.backgroundColor = .red
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testManeuverViewNotAbbreviated() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        
        controller.turnArrowView.isEnd = true
        controller.distance = nil
        controller.shieldImage = shieldImage
        controller.destinationLabel.unabridgedText = "Spell out Avenue multiple lines"
        controller.destinationLabel.backgroundColor = .red
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testManeuverViewAbbreviated() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        
        controller.turnArrowView.isEnd = true
        controller.shieldImage = shieldImage
        controller.distance = 100
        controller.destinationLabel.unabridgedText = "This Drive Avenue should be abbreviated."
        controller.destinationLabel.backgroundColor = .red
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testManeuverViewNotAbbreviatedMultipleLines() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        
        controller.turnArrowView.isEnd = true
        controller.shieldImage = shieldImage
        controller.distance = nil
        controller.destinationLabel.unabridgedText = "Drive Avenue should be abbreviated on multiple lines. Drive Avenue should be abbreviated on multiple lines."
        controller.destinationLabel.backgroundColor = .red
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testManeuverViewLongDestinationWithDistance() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        
        controller.turnArrowView.isEnd = true
        controller.shieldImage = shieldImage
        controller.distance = 100
        controller.destinationLabel.unabridgedText = "Long destination / US-45 / Chicago / Indiana / Exit 204B / Long destination / US-45 / Chicago / Indiana / Exit 204B"
        controller.destinationLabel.backgroundColor = .red
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testPartiallyAbbreviated() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        
        controller.turnArrowView.isEnd = true
        controller.distance = 482
        controller.destinationLabel.unabridgedText = "East Market Street"
        controller.destinationLabel.backgroundColor = .red
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testRouteSwitching() {
        let bundle = Bundle(for: MapboxNavigationTests.self)
        var filePath = bundle.path(forResource: "UnionSquare-to-GGPark", ofType: "route")!
        let route = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as! Route
        route.accessToken = "foo"
        
        let navigation = NavigationViewController(for: route, directions: directions)
        navigation.loadViewIfNeeded()
        
        filePath = bundle.path(forResource: "GGPark-to-BernalHeights", ofType: "route")!
        let newRoute = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as! Route
        
        navigation.route = newRoute
        
        XCTAssertTrue(navigation.routeController.routeProgress.route == newRoute, "Route should be equal the new route")
        
        let tableViewController = navigation.tableViewController!
        let numberOfRows = tableViewController.tableView(tableViewController.tableView, numberOfRowsInSection: 0)
        XCTAssertTrue(numberOfRows == newRoute.legs[0].steps.count,
                      "It should be same amount of cells as steps in the new route")
    }
    
    func testLanes() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteMapViewController") as! RouteMapViewController
        XCTAssert(controller.view != nil)
        
        route.accessToken = bogusToken
        let routeController = RouteController(along: route, directions: directions)
        let steps = routeController.routeProgress.currentLeg.steps
        let stepWithLanes = steps[8]
        controller.updateLaneViews(step: stepWithLanes, alertLevel: .high)
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
