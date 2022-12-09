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

            let routeController = RouteController(indexedRouteResponse: IndexedRouteResponse(routeResponse: response,
                                                                                             routeIndex: 0),
                                                  customRoutingProvider: MapboxRoutingProvider(.offline),
                                                  dataSource: dataSource)

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
        
        let containsStepsTableView = stepsViewController.view.subviews.contains(stepsViewController.tableView)
        XCTAssertTrue(containsStepsTableView, "StepsViewController does not have a table subview")
        XCTAssertNotNil(stepsViewController.tableView, "TableView not initiated")
    }

    func testUpdateCell() {
        let stepsViewController = dependencies.stepsViewController

        // Test that Steps ViewController viewLoads
        XCTAssertNotNil(stepsViewController.view, "StepsViewController not initiated properly")

        let indexPath = IndexPath(row: 0, section: 0)
        let cell = StepTableViewCell()

        let expectedInstruction = Constants.route.legs[0].steps[1].instructionsDisplayedAlongStep?.last
        cell.separatorView.isHidden = true
        stepsViewController.updateCell(cell, at: indexPath)

        XCTAssertEqual(cell.instructionsView.primaryLabel.instruction, expectedInstruction?.primaryInstruction)
        XCTAssertEqual(cell.instructionsView.secondaryLabel.instruction, expectedInstruction?.secondaryInstruction)
        XCTAssertTrue(cell.instructionsView.stepListIndicatorView.isHidden)
        XCTAssertFalse(cell.separatorView.isHidden)

        let lastIndexPath = IndexPath(row: 3, section: 0)
        stepsViewController.updateCell(cell, at: lastIndexPath)
        XCTAssertTrue(cell.separatorView.isHidden)
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
