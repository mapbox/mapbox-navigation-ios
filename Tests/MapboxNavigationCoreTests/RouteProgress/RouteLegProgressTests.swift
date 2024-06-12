import _MapboxNavigationTestHelpers
import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative
import XCTest

final class RouteLegProgressTests: XCTestCase {
    var legProgress: RouteLegProgress!
    var leg: RouteLeg!

    override func setUp() {
        super.setUp()

        leg = .mock()
        legProgress = RouteLegProgress(leg: leg)
    }

    func testInitialProgressValues() {
        XCTAssertEqual(legProgress.fractionTraveled, 0)
        XCTAssertEqual(legProgress.distanceRemaining, 0)
        XCTAssertEqual(legProgress.distanceTraveled, 0)
        XCTAssertEqual(legProgress.durationRemaining, 0)
        XCTAssertEqual(legProgress.stepIndex, 0)
        XCTAssertEqual(legProgress.currentStepProgress.step, leg.steps.first)
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
        legProgress.update(using: status)
        XCTAssertEqual(legProgress.distanceTraveled, legValue)
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
        legProgress.update(using: status)
        XCTAssertEqual(legProgress.fractionTraveled, legValue)
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
        legProgress.update(using: status)
        XCTAssertEqual(legProgress.durationRemaining, legValue)
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
        legProgress.update(using: status)
        XCTAssertEqual(legProgress.distanceRemaining, legValue)
    }

    func testStepIndex() {
        let stepIndex = 1
        let status = NavigationStatus.mock(stepIndex: UInt32(stepIndex))
        legProgress.update(using: status)
        XCTAssertEqual(legProgress.stepIndex, stepIndex)
        XCTAssertEqual(legProgress.currentStepProgress.step, leg.steps[stepIndex])

        let incorrectStepIndex = 10 // Index out of bounds
        let statusIncorrectIndex = NavigationStatus.mock(stepIndex: UInt32(incorrectStepIndex))
        legProgress.update(using: statusIncorrectIndex)
        XCTAssertEqual(legProgress.stepIndex, stepIndex, "Ignores index out of bounds")
    }

    func testShapeIndex() {
        let stepIndex = 1
        let shapeIndex = 5
        let status = NavigationStatus.mock(
            stepIndex: UInt32(stepIndex),
            shapeIndex: UInt32(shapeIndex)
        )
        legProgress.update(using: status)
        XCTAssertEqual(legProgress.shapeIndex, shapeIndex)
    }

    func testIgnoreStatusWithoutActiveGuidanceInfo() {
        let stepIndex = 1
        let status = NavigationStatus.mock(
            activeGuidanceInfo: nil,
            stepIndex: UInt32(stepIndex)
        )
        legProgress.update(using: status)
        XCTAssertEqual(legProgress.stepIndex, 0)
    }

    func testCurrentSpeedLimitIfNilLimit() {
        let status = NavigationStatus.mock(
            speedLimit: .init(speed: nil, localeUnit: .milesPerHour, localeSign: .mutcd)
        )
        legProgress.update(using: status)
        XCTAssertNil(legProgress.currentSpeedLimit)
    }

    func testCurrentSpeedLimitIfMilesPerHour() {
        let status = NavigationStatus.mock(
            speedLimit: .init(speed: 30, localeUnit: .milesPerHour, localeSign: .mutcd)
        )
        legProgress.update(using: status)
        XCTAssertEqual(legProgress.currentSpeedLimit, .init(value: 30, unit: .milesPerHour))
    }

    func testCurrentSpeedLimitIfKilometresPerHour() {
        let status = NavigationStatus.mock(
            speedLimit: .init(speed: 30, localeUnit: .kilometresPerHour, localeSign: .mutcd)
        )
        legProgress.update(using: status)
        XCTAssertEqual(legProgress.currentSpeedLimit, .init(value: 30, unit: .kilometersPerHour))
    }

    func testUserHasArrivedAtWaypointIfNotCompleteAnd3StepsLeft() {
        let status = NavigationStatus.mock(
            routeState: .tracking,
            stepIndex: 0
        )
        legProgress.update(using: status)
        XCTAssertFalse(legProgress.userHasArrivedAtWaypoint)
    }

    func testUserHasArrivedAtWaypointIfNotCompleteAnd2StepsLeft() {
        let status = NavigationStatus.mock(
            routeState: .tracking,
            stepIndex: 1
        )
        legProgress.update(using: status)
        XCTAssertFalse(legProgress.userHasArrivedAtWaypoint)
    }

    func testUserHasArrivedAtWaypointIfCompleteAnd3StepLeft() {
        let status = NavigationStatus.mock(
            routeState: .complete,
            stepIndex: 0
        )
        legProgress.update(using: status)
        XCTAssertFalse(legProgress.userHasArrivedAtWaypoint)
    }

    func testUserHasArrivedAtWaypointIfCompleteAnd2StepsLeft() {
        let status = NavigationStatus.mock(
            routeState: .complete,
            stepIndex: 1
        )
        legProgress.update(using: status)
        XCTAssertTrue(legProgress.userHasArrivedAtWaypoint)
    }

    func testUpdateStepProgressIfMovedToNextStep() {
        let stepIndex = 1
        let stepDistanceTraveled = 100.0
        let status = NavigationStatus.mock(
            activeGuidanceInfo: .mock(
                stepProgress: .mock(distanceTraveled: stepDistanceTraveled)
            ),
            stepIndex: UInt32(stepIndex)
        )
        legProgress.update(using: status)
        XCTAssertEqual(legProgress.currentStepProgress.distanceTraveled, stepDistanceTraveled)
        XCTAssertEqual(legProgress.currentStepProgress.step, leg.steps[stepIndex])
    }

    func testUpdateStepProgressIfNotMovedToNextStep() {
        let stepIndex = 0
        let stepDistanceTraveled = 100.0
        let status = NavigationStatus.mock(
            activeGuidanceInfo: .mock(
                stepProgress: .mock(distanceTraveled: stepDistanceTraveled)
            ),
            stepIndex: UInt32(stepIndex)
        )
        legProgress.update(using: status)
        XCTAssertEqual(legProgress.currentStepProgress.distanceTraveled, stepDistanceTraveled)
        XCTAssertEqual(legProgress.currentStepProgress.step, leg.steps.first)
    }

    func testRemainingSteps() {
        XCTAssertEqual(legProgress.remainingSteps, Array(leg.steps.suffix(from: 1)))

        let status = NavigationStatus.mock(
            stepIndex: UInt32(1)
        )
        let expectedSteps = [leg.steps[2], leg.steps[3]]
        legProgress.update(using: status)
        XCTAssertEqual(legProgress.remainingSteps, expectedSteps)

        let lastStepStatus = NavigationStatus.mock(stepIndex: UInt32(3))
        legProgress.update(using: lastStepStatus)
        XCTAssertEqual(legProgress.remainingSteps, [])
    }

    func testStepBefore() {
        XCTAssertNil(legProgress.stepBefore(leg.steps[0]))
        XCTAssertEqual(legProgress.stepBefore(leg.steps[1]), leg.steps[0])
        XCTAssertEqual(legProgress.stepBefore(leg.steps[3]), leg.steps[2])
        let nonLegStep = RouteStep.mock()
        XCTAssertNil(legProgress.stepBefore(nonLegStep))
    }

    func testStepAfter() {
        XCTAssertNil(legProgress.stepAfter(leg.steps[3]))
        XCTAssertEqual(legProgress.stepAfter(leg.steps[0]), leg.steps[1])
        XCTAssertEqual(legProgress.stepAfter(leg.steps[2]), leg.steps[3])
        let nonLegStep = RouteStep.mock()
        XCTAssertNil(legProgress.stepAfter(nonLegStep))
    }

    func testPriorStep() {
        XCTAssertNil(legProgress.priorStep)

        let lastStepStatus = NavigationStatus.mock(stepIndex: UInt32(3))
        legProgress.update(using: lastStepStatus)
        XCTAssertEqual(legProgress.priorStep, leg.steps[2])
    }

    func testUpcomingStep() {
        XCTAssertEqual(legProgress.upcomingStep, leg.steps[1])

        let lastStepStatus = NavigationStatus.mock(stepIndex: UInt32(3))
        legProgress.update(using: lastStepStatus)
        XCTAssertNil(legProgress.upcomingStep)
    }

    func testFollowOnStep() {
        XCTAssertEqual(legProgress.followOnStep, leg.steps[2])

        let step1Status = NavigationStatus.mock(stepIndex: UInt32(1))
        legProgress.update(using: step1Status)
        XCTAssertEqual(legProgress.followOnStep, leg.steps[3])

        let step2Status = NavigationStatus.mock(stepIndex: UInt32(2))
        legProgress.update(using: step2Status)
        XCTAssertNil(legProgress.followOnStep)

        let lastStepStatus = NavigationStatus.mock(stepIndex: UInt32(3))
        legProgress.update(using: lastStepStatus)
        XCTAssertNil(legProgress.followOnStep)
    }

    func testIsCurrentStep() {
        XCTAssertTrue(legProgress.isCurrentStep(leg.steps[0]))
        XCTAssertFalse(legProgress.isCurrentStep(leg.steps[2]))
        XCTAssertFalse(legProgress.isCurrentStep(.mock()))
    }

    func testRefreshLeg() {
        let newLeg = RouteLeg.mock(profileIdentifier: .cycling)
        let newLegProgress = legProgress.refreshingLeg(with: newLeg)
        XCTAssertEqual(newLegProgress.leg, newLeg)
    }
}
