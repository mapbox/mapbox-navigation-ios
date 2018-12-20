import Foundation
import XCTest
import MapboxDirections
@testable import MapboxCoreNavigation

class RouteProgressTests: XCTestCase {
    func testRouteProgress() {
        let routeProgress = RouteProgress(route: route)
        XCTAssertEqual(routeProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.distanceRemaining, 4054.2)
        XCTAssertEqual(routeProgress.distanceTraveled, 0)
        XCTAssertEqual(round(routeProgress.durationRemaining), 858)
    }
    
    func testRouteLegProgress() {
        let routeProgress = RouteProgress(route: route)
        XCTAssertEqual(routeProgress.currentLeg.description, "Hyde Street, Page Street")
        XCTAssertEqual(routeProgress.currentLegProgress.distanceTraveled, 0)
        XCTAssertEqual(round(routeProgress.currentLegProgress.durationRemaining), 858)
        XCTAssertEqual(routeProgress.currentLegProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.stepIndex, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.followOnStep?.description, "Turn left onto Hyde Street")
        XCTAssertEqual(routeProgress.currentLegProgress.upcomingStep?.description, "Turn right onto California Street")
    }
    
    func testRouteStepProgress() {
        let routeProgress = RouteProgress(route: route)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceRemaining, 384.1)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.durationRemaining, 86.6, accuracy: 0.001)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation, Double.infinity)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.step.description, "Head south on Taylor Street")
    }
    
    func testNextRouteStepProgress() {
        let routeProgress = RouteProgress(route: route)
        routeProgress.currentLegProgress.stepIndex = 1
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceRemaining, 439.1)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceTraveled, 0)
        XCTAssertEqual(round(routeProgress.currentLegProgress.currentStepProgress.durationRemaining), 73)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation, Double.infinity)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.step.description, "Turn right onto California Street")
    }
}
