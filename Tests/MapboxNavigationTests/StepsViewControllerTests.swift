import XCTest
import MapboxDirections
import CoreLocation
@testable import TestHelper
@testable import MapboxCoreNavigation
@testable import MapboxNavigation

class StepsViewControllerTests: TestCase {
    struct Constants {
        static let route = response.routes!.first!
        static let options = routeOptions
        static let credentials = Fixture.credentials
    }
    
    var dependencies: (stepsViewController: StepsViewController, routeController: RouteController, firstLocation: CLLocation, lastLocation: CLLocation)!

    override func setUp() {
        super.setUp()

        dependencies = {
            let dataSource = RouteControllerDataSourceFake()

            let routeController = RouteController(alongRouteAtIndex: 0, in: response, options: Constants.options, customRoutingProvider: MapboxRoutingProvider(.offline), dataSource: dataSource)

            let stepsViewController = StepsViewController(routeProgress: routeController.routeProgress)

            let firstCoord = routeController.routeProgress.nearbyShape.coordinates.first!
            let firstLocation = CLLocation(coordinate: firstCoord, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date())

            let lastCoord = routeController.routeProgress.currentLegProgress.remainingSteps.last!.shape!.coordinates.first!
            let lastLocation = CLLocation(coordinate: lastCoord, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date())

            return (stepsViewController: stepsViewController, routeController: routeController, firstLocation: firstLocation, lastLocation: lastLocation)
        }()
    }

    override func tearDown() {
        super.tearDown()
        dependencies = nil
    }
    
    func testRebuildStepsInstructionsViewDataSource() {
        let stepsViewController = dependencies.stepsViewController

        XCTAssertNotNil(stepsViewController.view, "StepsViewController not initiated properly")
//        measure {
//            // Measure Performance - stepsViewController.rebuildDataSourceIfNecessary()
//        }
        
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
