import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
@testable import MapboxNavigationUIKit
@testable import TestHelper
import XCTest

@MainActor
class StepsViewControllerTests: TestCase {
    enum Constants {
        static let route = Fixture.route(from: "routeWithInstructions", options: routeOptions)
        static let options = routeOptions
        static let credentials = Fixture.credentials
    }

    private func createStepsViewController() async -> StepsViewController {
        let routes = await Fixture.navigationRoutes(from: "routeWithInstructions", options: Constants.options)
        let routeProgress = RouteProgress(
            navigationRoutes: routes,
            waypoints: Constants.options.waypoints,
            congestionConfiguration: .default
        )
        return StepsViewController(routeProgress: routeProgress)
    }

    func testRebuildStepsInstructionsViewDataSource() async {
        let stepsViewController = await createStepsViewController()

        XCTAssertNotNil(stepsViewController.view, "StepsViewController not initiated properly")

        let containsStepsTableView = stepsViewController.view.subviews.contains(stepsViewController.tableView)
        XCTAssertTrue(containsStepsTableView, "StepsViewController does not have a table subview")
        XCTAssertNotNil(stepsViewController.tableView, "TableView not initiated")
    }

    func testUpdateCell() async {
        let stepsViewController = await createStepsViewController()

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
    private func location(at coordinate: CLLocationCoordinate2D) -> CLLocation {
        return CLLocation(
            coordinate: coordinate,
            altitude: 5,
            horizontalAccuracy: 10,
            verticalAccuracy: 5,
            course: 20,
            speed: 15,
            timestamp: Date()
        )
    }
}
