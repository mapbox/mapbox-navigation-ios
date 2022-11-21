import XCTest
import MapboxDirections
import CoreLocation
@testable import TestHelper
@testable import MapboxCoreNavigation

final class RouteStepProgressTests: TestCase {
    let accuracy: CLLocationDistance = 0.00001

    var zeroDistanceStep: RouteStep!
    var step: RouteStep!
    var stepProgress: RouteStepProgress!
    var intersections: [Intersection]!

    override func setUp() {
        super.setUp()
        
        step = RouteStep(transportType: .automobile,
                         maneuverLocation: .init(),
                         maneuverType: .turn,
                         instructions: "empty",
                         drivingSide: .right,
                         distance: 100,
                         expectedTravelTime: 10)
        zeroDistanceStep = RouteStep(transportType: .automobile,
                                     maneuverLocation: .init(),
                                     maneuverType: .turn,
                                     instructions: "empty",
                                     drivingSide: .right,
                                     distance: 0,
                                     expectedTravelTime: 10)
        stepProgress = RouteStepProgress(step: step)

        intersections = [
            Intersection(location: CLLocationCoordinate2D(latitude: 38.878206, longitude: -77.037265),
                         headings: [],
                         approachIndex: 0,
                         outletIndex: 0,
                         outletIndexes:  .init(integer: 0),
                         approachLanes: nil,
                         usableApproachLanes: nil,
                         preferredApproachLanes: nil,
                         usableLaneIndication: nil),
            Intersection(location: CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906),
                         headings: [],
                         approachIndex: 0,
                         outletIndex: 0,
                         outletIndexes:  .init(integer: 0),
                         approachLanes: nil,
                         usableApproachLanes: nil,
                         preferredApproachLanes: nil,
                         usableLaneIndication: nil),
        ]
    }

    func testReturnUpcomingIntersection() {
        XCTAssertNil(stepProgress.upcomingIntersection, "Should return nil if empty intersectionsIncludingUpcomingManeuverIntersection")

        stepProgress.intersectionsIncludingUpcomingManeuverIntersection = intersections
        XCTAssertEqual(stepProgress.upcomingIntersection, intersections[1], "Should return next intersection")

        stepProgress.intersectionIndex = 1
        XCTAssertNil(stepProgress.upcomingIntersection)

        stepProgress.intersectionIndex = -1
        XCTAssertNil(stepProgress.upcomingIntersection)
    }

    func testReturnCurrentIntersection() {
        XCTAssertNil(stepProgress.currentIntersection)

        stepProgress.intersectionsIncludingUpcomingManeuverIntersection = intersections
        XCTAssertEqual(stepProgress.currentIntersection, intersections[0])

        stepProgress.intersectionIndex = 1
        XCTAssertEqual(stepProgress.currentIntersection, intersections[1])

        stepProgress.intersectionIndex = 2
        XCTAssertNil(stepProgress.currentIntersection)

        stepProgress.intersectionIndex = -1
        XCTAssertNil(stepProgress.currentIntersection)
    }

    func testReturnDistanceRemaining() {
        XCTAssertEqual(stepProgress.distanceRemaining, 100)

        stepProgress.distanceTraveled = 90
        XCTAssertEqual(stepProgress.distanceRemaining, 10)
    }

    func testReturnDurationRemaining() {
        XCTAssertEqual(stepProgress.durationRemaining, 10)

        stepProgress.distanceTraveled = 90
        XCTAssertEqual(stepProgress.durationRemaining, 1, accuracy: accuracy)

        let stepProgress = RouteStepProgress(step: zeroDistanceStep)
        XCTAssertEqual(stepProgress.durationRemaining, 0)
    }

    func testReturnFractionTraveled() {
        XCTAssertEqual(stepProgress.fractionTraveled, 0)

        stepProgress.distanceTraveled = 90
        XCTAssertEqual(stepProgress.fractionTraveled, 0.9)

        stepProgress.distanceTraveled = 100
        XCTAssertEqual(stepProgress.fractionTraveled, 1)

        let stepProgress = RouteStepProgress(step: zeroDistanceStep)
        XCTAssertEqual(stepProgress.fractionTraveled, 1)
    }

    func testReturnInitialUserDistanceToManeuverLocation() {
        XCTAssertEqual(stepProgress.userDistanceToManeuverLocation, step.distance)
    }

}
