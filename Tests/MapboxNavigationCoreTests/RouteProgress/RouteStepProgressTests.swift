import _MapboxNavigationTestHelpers
import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative
import XCTest

private let spokenInstructions: [SpokenInstruction] = [
    .mock(),
    .mock(),
]
private let visualInstructions: [VisualInstructionBanner] = [
    .mock(maneuverType: .depart),
    .mock(maneuverType: .turn),
    .mock(maneuverType: .arrive),
]
private let accuracy: CLLocationDistance = 0.00001
private let distance: CLLocationDistance = 100

final class RouteStepProgressTests: XCTestCase {
    var stepProgress: RouteStepProgress!
    var intersections: [Intersection]!

    override func setUp() {
        super.setUp()

        stepProgress = makeStepProgress()

        intersections = [
            Intersection(
                location: CLLocationCoordinate2D(latitude: 38.878206, longitude: -77.037265),
                headings: [],
                approachIndex: 0,
                outletIndex: 0,
                outletIndexes: .init(integer: 0),
                approachLanes: nil,
                usableApproachLanes: nil,
                preferredApproachLanes: nil,
                usableLaneIndication: nil
            ),
            Intersection(
                location: CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906),
                headings: [],
                approachIndex: 0,
                outletIndex: 0,
                outletIndexes: .init(integer: 0),
                approachLanes: nil,
                usableApproachLanes: nil,
                preferredApproachLanes: nil,
                usableLaneIndication: nil
            ),
        ]
    }

    func makeStepProgress(
        distance: CLLocationDistance = distance,
        instructionsSpokenAlongStep: [SpokenInstruction]? = spokenInstructions,
        instructionsDisplayedAlongStep: [VisualInstructionBanner]? = visualInstructions
    )
    -> RouteStepProgress {
        let step = RouteStep(
            transportType: .automobile,
            maneuverLocation: .init(),
            maneuverType: .turn,
            instructions: "empty",
            drivingSide: .right,
            distance: distance,
            expectedTravelTime: 10,
            instructionsSpokenAlongStep: instructionsSpokenAlongStep,
            instructionsDisplayedAlongStep: instructionsDisplayedAlongStep
        )
        return RouteStepProgress(step: step)
    }

    func testInitialProgressValues() {
        XCTAssertEqual(stepProgress.fractionTraveled, 0)
        XCTAssertEqual(stepProgress.distanceRemaining, 0)
        XCTAssertEqual(stepProgress.distanceTraveled, 0)
        XCTAssertEqual(stepProgress.durationRemaining, 0)
    }

    func testReturnDistanceTraveled() {
        let stepValue = 100.0
        let legValue = 200.0
        let routeValue = 300.0
        let status = NavigationStatus.mock(
            activeGuidanceInfo: .mock(
                routeProgress: .mock(distanceTraveled: routeValue),
                legProgress: .mock(distanceTraveled: legValue),
                stepProgress: .mock(distanceTraveled: stepValue)
            )
        )
        stepProgress.update(using: status)
        XCTAssertEqual(stepProgress.distanceTraveled, stepValue)
    }

    func testReturnFractionTraveled() {
        let stepValue = 100.0
        let legValue = 200.0
        let routeValue = 300.0
        let status = NavigationStatus.mock(
            activeGuidanceInfo: .mock(
                routeProgress: .mock(fractionTraveled: routeValue),
                legProgress: .mock(fractionTraveled: legValue),
                stepProgress: .mock(fractionTraveled: stepValue)
            )
        )
        stepProgress.update(using: status)
        XCTAssertEqual(stepProgress.fractionTraveled, stepValue)
    }

    func testReturnRemainingDuration() {
        let stepValue = 100.0
        let legValue = 200.0
        let routeValue = 300.0
        let status = NavigationStatus.mock(
            activeGuidanceInfo: .mock(
                routeProgress: .mock(remainingDuration: routeValue),
                legProgress: .mock(remainingDuration: legValue),
                stepProgress: .mock(remainingDuration: stepValue)
            )
        )
        stepProgress.update(using: status)
        XCTAssertEqual(stepProgress.durationRemaining, stepValue)
    }

    func testReturnDistanceRemaining() {
        let stepValue = 100.0
        let legValue = 200.0
        let routeValue = 300.0
        let status = NavigationStatus.mock(
            activeGuidanceInfo: .mock(
                routeProgress: .mock(remainingDistance: routeValue),
                legProgress: .mock(remainingDistance: legValue),
                stepProgress: .mock(remainingDistance: stepValue)
            )
        )
        stepProgress.update(using: status)
        XCTAssertEqual(stepProgress.distanceRemaining, stepValue)
    }

    func testReturnUpcomingIntersection() {
        XCTAssertNil(
            stepProgress.upcomingIntersection,
            "Should return nil if empty intersectionsIncludingUpcomingManeuverIntersection"
        )

        stepProgress.intersectionsIncludingUpcomingManeuverIntersection = intersections
        XCTAssertEqual(stepProgress.upcomingIntersection, intersections[1], "Should return next intersection")

        let status1 = NavigationStatus.mock(intersectionIndex: 1)
        stepProgress.update(using: status1)
        XCTAssertNil(stepProgress.upcomingIntersection)

        let status10 = NavigationStatus.mock(intersectionIndex: 10)
        stepProgress.update(using: status10)
        XCTAssertNil(stepProgress.upcomingIntersection)
    }

    func testReturnCurrentIntersection() {
        XCTAssertNil(stepProgress.currentIntersection)

        stepProgress.intersectionsIncludingUpcomingManeuverIntersection = intersections
        XCTAssertEqual(stepProgress.currentIntersection, intersections[0])

        let status1 = NavigationStatus.mock(intersectionIndex: 1)
        stepProgress.update(using: status1)
        XCTAssertEqual(stepProgress.currentIntersection, intersections[1])

        let status2 = NavigationStatus.mock(intersectionIndex: 2)
        stepProgress.update(using: status2)
        XCTAssertNil(stepProgress.currentIntersection)

        let status10 = NavigationStatus.mock(intersectionIndex: 10)
        stepProgress.update(using: status10)
        XCTAssertNil(stepProgress.currentIntersection)
    }

    func testReturnInitialUserDistanceToUpcomingIntersection() {
        XCTAssertNil(stepProgress.userDistanceToUpcomingIntersection)
    }

    func testReturnRemainingSpokenInstructions() {
        XCTAssertNil(stepProgress.remainingSpokenInstructions)

        let status1 = NavigationStatus.mock(voiceInstruction: .mock(index: 1))
        stepProgress.update(using: status1)
        XCTAssertEqual(stepProgress.remainingSpokenInstructions, Array(spokenInstructions.suffix(from: 1)))

        let status2 = NavigationStatus.mock(voiceInstruction: .mock(index: 2))
        stepProgress.update(using: status2)
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

        let status1 = NavigationStatus.mock(bannerInstruction: .mock(index: 1))
        stepProgress.update(using: status1)
        XCTAssertEqual(stepProgress.remainingVisualInstructions, Array(visualInstructions.suffix(from: 1)))

        let status3 = NavigationStatus.mock(bannerInstruction: .mock(index: 3))
        stepProgress.update(using: status3)
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
        let mock = VoiceInstruction.mock()
        let expectedSpokenInstructions = SpokenInstruction(mock)
        let status1 = NavigationStatus.mock(voiceInstruction: .mock(index: 1))
        stepProgress.update(using: status1)
        XCTAssertEqual(stepProgress.currentSpokenInstruction, expectedSpokenInstructions)

        let status3 = NavigationStatus.mock(voiceInstruction: .mock(index: 3))
        stepProgress.update(using: status3)
        XCTAssertEqual(stepProgress.currentSpokenInstruction, expectedSpokenInstructions)

        let stepProgressWithEmptyInstructions = makeStepProgress(instructionsSpokenAlongStep: [])
        XCTAssertNil(stepProgressWithEmptyInstructions.currentSpokenInstruction)
    }

    func testReturnCurrentVisualInstruction() {
        let status1 = NavigationStatus.mock(bannerInstruction: .mock(index: 1))
        stepProgress.update(using: status1)
        XCTAssertEqual(stepProgress.currentVisualInstruction, visualInstructions[1])

        let status3 = NavigationStatus.mock(bannerInstruction: .mock(index: 3))
        stepProgress.update(using: status3)
        XCTAssertNil(stepProgress.currentVisualInstruction)

        let stepProgressWithEmptyInstructions = makeStepProgress(instructionsDisplayedAlongStep: [])
        XCTAssertNil(stepProgressWithEmptyInstructions.currentVisualInstruction)
    }
}
