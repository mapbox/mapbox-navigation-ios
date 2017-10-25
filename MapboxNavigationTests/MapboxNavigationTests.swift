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
        styleInstructionsView(controller.instructionsBannerView)
        
        controller.distance = 1608
        controller.instructionsBannerView.turnArrowView.isEnd = true
        controller.instructionsBannerView.set(primary: "This should be multiple lines", secondary: "This should be multiple lines")
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testManeuverViewSingleLine() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        styleInstructionsView(controller.instructionsBannerView)
        
        controller.distance = 804
        controller.instructionsBannerView.turnArrowView.isEnd = true
        controller.instructionsBannerView.set(primary: "Primary label only", secondary: nil)
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testManeuverViewNotAbbreviated() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        styleInstructionsView(controller.instructionsBannerView)
        
        controller.distance = 804
        controller.instructionsBannerView.turnArrowView.isEnd = true
        controller.instructionsBannerView.set(primary: "Spell out Avenue multiple lines", secondary: nil)
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testManeuverViewAbbreviated() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        styleInstructionsView(controller.instructionsBannerView)
        
        controller.instructionsBannerView.turnArrowView.isEnd = true
        controller.distance = 100
        controller.instructionsBannerView.set(primary: "This Drive Avenue should be abbreviated.", secondary: nil)
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testManeuverViewNotAbbreviatedMultipleLines() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        styleInstructionsView(controller.instructionsBannerView)
        
        controller.instructionsBannerView.turnArrowView.isEnd = true
        controller.distance = 804
        controller.instructionsBannerView.set(primary: "I-80 / South", secondary: "Drive Avenue should be abbreviated on multiple lines.")
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testManeuverViewLongDestinationWithDistance() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        styleInstructionsView(controller.instructionsBannerView)
        
        controller.instructionsBannerView.turnArrowView.isEnd = true
        controller.distance = 100
        controller.instructionsBannerView.set(primary: "I-80", secondary: "HMM Long destination / US-45 / Chicago")
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testPartiallyAbbreviated() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        styleInstructionsView(controller.instructionsBannerView)
        
        controller.instructionsBannerView.turnArrowView.isEnd = true
        controller.distance = 482
        controller.instructionsBannerView.set(primary: "I-80", secondary: "East Market Street")
        
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
        controller.updateLaneViews(step: stepWithLanes, durationRemaining: 20)
        controller.showLaneViews(animated: false)
        
        FBSnapshotVerifyView(controller.laneViewsContainerView)
    }
}

extension MapboxNavigationTests {
    // UIAppearance proxy do not work in unit test environment so we have to style manually
    func styleInstructionsView(_ view: InstructionsBannerView) {
        view.backgroundColor = .white
        view.turnArrowView.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        view.distanceLabel.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        view.primaryLabel.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        view.secondaryLabel.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        view.distanceLabel.font = UIFont.systemFont(ofSize: 16)
        view.primaryLabel.font = UIFont.systemFont(ofSize: 32, weight: UIFontWeightMedium)
        view.secondaryLabel.font = UIFont.systemFont(ofSize: 24, weight: UIFontWeightMedium)
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
