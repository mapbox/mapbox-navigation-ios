import XCTest
import MapboxDirections
@testable import MapboxCoreNavigation
@testable import MapboxNavigation

class StepsViewControllerTests: XCTestCase {
    
    struct Constants {
        static let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String: Any]
        static let accessToken = "nonsense"
    }
    
    lazy var dependencies: (stepsViewController: StepsViewController, routeController: RouteController, firstLocation: CLLocation, lastLocation: CLLocation) = {
        
        let bogusToken = "pk.feedCafeDeadBeefBadeBede"
        let directions = Directions(accessToken: bogusToken)

        let routeController = RouteController(along: initialRoute, directions: directions)
        
        let stepsViewController = StepsViewController(routeProgress: routeController.routeProgress)
        
        let firstCoord = routeController.routeProgress.currentLegProgress.nearbyCoordinates.first!
        let firstLocation = CLLocation(coordinate: firstCoord, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date())
        
        let lastCoord = routeController.routeProgress.currentLegProgress.remainingSteps.last!.coordinates!.first!
        let lastLocation = CLLocation(coordinate: lastCoord, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date())
        
        return (stepsViewController: stepsViewController, routeController: routeController, firstLocation: firstLocation, lastLocation: lastLocation)
    }()
    
    lazy var initialRoute: Route = {
        let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161))
        let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412))
        let route = Route(json: Constants.jsonRoute, waypoints: [waypoint1, waypoint2], options: NavigationRouteOptions(waypoints: [waypoint1, waypoint2]))
        route.accessToken = "nonsense"
        return route
    }()
    
    func testRebuildStepsInstructionsViewDataSource() {
        
        let stepsViewController = dependencies.stepsViewController

        measure {
            // Measure Performance - stepsViewController.rebuildDataSourceIfNecessary()
            XCTAssertNotNil(stepsViewController.view, "StepsViewController not initiated properly")
        }
        
        let containsStepsTableView = stepsViewController.view.subviews.contains(stepsViewController.tableView)
        XCTAssertTrue(containsStepsTableView, "StepsViewController does not have a table subview")
        XCTAssertNotNil(stepsViewController.tableView, "TableView not initiated")
    }

    /// NOTE: This test is disabled pending https://github.com/mapbox/mapbox-navigation-ios/issues/1468
    func x_testUpdateCellPerformance() {
        
        let stepsViewController = dependencies.stepsViewController
        
        // Test that Steps ViewController viewLoads
        XCTAssertNotNil(stepsViewController.view, "StepsViewController not initiated properly")
        
        let stepsTableView = stepsViewController.tableView!
        
        measure {
            for i in 0..<stepsTableView.numberOfRows(inSection: 0) {
                let indexPath = IndexPath(row: i, section: 0)
                if let cell = stepsTableView.cellForRow(at: indexPath) as? StepTableViewCell {
                    stepsViewController.updateCell(cell, at: indexPath)
                }
            }
        }
    }

}

extension StepsViewControllerTests {
    fileprivate func location(at coordinate: CLLocationCoordinate2D) -> CLLocation {
                return CLLocation(coordinate: coordinate,
                                    altitude: 5,
                          horizontalAccuracy: 10,
                            verticalAccuracy: 5,
                                      course: 20,
                                       speed: 15,
                                   timestamp: Date())
    }
}
