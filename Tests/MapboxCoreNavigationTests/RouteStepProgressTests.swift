import XCTest
import MapboxDirections
import CoreLocation
@testable import TestHelper
@testable import MapboxCoreNavigation

fileprivate let spokenInstructions = [
    Fixture.makeSpokenInstruction(),
    Fixture.makeSpokenInstruction()
]
fileprivate let visualInstructions = [
    Fixture.makeVisualInstruction(maneuverType: .depart),
    Fixture.makeVisualInstruction(maneuverType: .turn),
    Fixture.makeVisualInstruction(maneuverType: .arrive)
]
fileprivate let accuracy: CLLocationDistance = 0.00001
fileprivate let distance: CLLocationDistance = 100

final class RouteStepProgressTests: TestCase {
    var stepProgress: RouteStepProgress!
    var intersections: [Intersection]!

    override func setUp() {
        super.setUp()

        stepProgress = makeStepProgress()

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

    func makeStepProgress(distance: CLLocationDistance = distance,
                          instructionsSpokenAlongStep: [SpokenInstruction]? = spokenInstructions,
                          instructionsDisplayedAlongStep: [VisualInstructionBanner]? = visualInstructions) -> RouteStepProgress {
        let step = RouteStep(transportType: .automobile,
                         maneuverLocation: .init(),
                         maneuverType: .turn,
                         instructions: "empty",
                         drivingSide: .right,
                         distance: distance,
                         expectedTravelTime: 10,
                         instructionsSpokenAlongStep: instructionsSpokenAlongStep,
                         instructionsDisplayedAlongStep: instructionsDisplayedAlongStep)
        return RouteStepProgress(step: step)
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

        let stepProgress = makeStepProgress(distance: 0)
        XCTAssertEqual(stepProgress.durationRemaining, 0)
    }

    func testReturnFractionTraveled() {
        XCTAssertEqual(stepProgress.fractionTraveled, 0)

        stepProgress.distanceTraveled = 90
        XCTAssertEqual(stepProgress.fractionTraveled, 0.9)

        stepProgress.distanceTraveled = 100
        XCTAssertEqual(stepProgress.fractionTraveled, 1)

        let stepProgress = makeStepProgress(distance: 0)
        XCTAssertEqual(stepProgress.fractionTraveled, 1)
    }

    func testReturnInitialUserDistanceToManeuverLocation() {
        XCTAssertEqual(stepProgress.userDistanceToManeuverLocation, distance)
    }

    func testReturnRemainingSpokenInstructions() {
        XCTAssertEqual(stepProgress.remainingSpokenInstructions, spokenInstructions)

        stepProgress.spokenInstructionIndex = 1
        XCTAssertEqual(stepProgress.remainingSpokenInstructions, Array(spokenInstructions.suffix(from: 1)))

        stepProgress.spokenInstructionIndex = 2
        XCTAssertNil(stepProgress.remainingSpokenInstructions)
    }

    func testReturnRemainingSpokenInstructionsIfNil() {
        let stepProgress = makeStepProgress(instructionsSpokenAlongStep: nil)
        XCTAssertNil(stepProgress.remainingSpokenInstructions)
    }

    func testReturnRemainingSpokenInstructionsIfEmpty() {
        let stepProgress = makeStepProgress(instructionsSpokenAlongStep: [])
        XCTAssertNil(stepProgress.remainingSpokenInstructions)
    }

    func testReturnRemainingVisualInstructions() {
        XCTAssertEqual(stepProgress.remainingVisualInstructions, visualInstructions)

        stepProgress.visualInstructionIndex = 1
        XCTAssertEqual(stepProgress.remainingVisualInstructions, Array(visualInstructions.suffix(from: 1)))

        stepProgress.visualInstructionIndex = 3
        XCTAssertNil(stepProgress.remainingVisualInstructions)
    }

    func testReturnRemainingVisualInstructionsIfNil() {
        let stepProgress = makeStepProgress(instructionsDisplayedAlongStep: nil)
        XCTAssertNil(stepProgress.remainingVisualInstructions)
    }

    func testReturnRemainingVisualInstructionsIfEmpty() {
        let stepProgress = makeStepProgress(instructionsDisplayedAlongStep: [])
        XCTAssertNil(stepProgress.remainingVisualInstructions)
    }

    func testReturnCurrentSpokenInstruction() {
        stepProgress.spokenInstructionIndex = 1
        XCTAssertEqual(stepProgress.currentSpokenInstruction, spokenInstructions[1])

        stepProgress.spokenInstructionIndex = 2
        XCTAssertNil(stepProgress.currentSpokenInstruction)

        stepProgress.spokenInstructionIndex = -1
        XCTAssertNil(stepProgress.currentSpokenInstruction)

        let stepProgressWithEmptyInstructions = makeStepProgress(instructionsSpokenAlongStep: [])
        XCTAssertNil(stepProgressWithEmptyInstructions.currentSpokenInstruction)
    }

    func testReturnCurrentVisualInstruction() {
        stepProgress.visualInstructionIndex = 1
        XCTAssertEqual(stepProgress.currentVisualInstruction, visualInstructions[1])

        stepProgress.visualInstructionIndex = 3
        XCTAssertNil(stepProgress.currentVisualInstruction)

        stepProgress.visualInstructionIndex = -1
        XCTAssertNil(stepProgress.currentVisualInstruction)

        let stepProgressWithEmptyInstructions = makeStepProgress(instructionsDisplayedAlongStep: [])
        XCTAssertNil(stepProgressWithEmptyInstructions.currentVisualInstruction)
    }

}
