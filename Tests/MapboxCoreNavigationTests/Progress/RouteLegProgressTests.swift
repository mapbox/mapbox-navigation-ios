import XCTest
import MapboxDirections
import CoreLocation
@testable import TestHelper
@testable import MapboxCoreNavigation

final class RouteLegProgressTests: TestCase {
    var legProgress: RouteLegProgress!
    var leg: RouteLeg!

    override func setUp() {
        super.setUp()

        leg = makeRoute().legs[0]
        legProgress = RouteLegProgress(leg: leg)
    }

    func testReturnDistanceTraveled() {
        let distance = 10.0
        legProgress.currentStepProgress.distanceTraveled = distance
        XCTAssertEqual(legProgress.distanceTraveled, distance)

        legProgress.stepIndex = 1
        legProgress.currentStepProgress.distanceTraveled = distance
        XCTAssertEqual(legProgress.distanceTraveled, distance + leg.steps[0].distance)
    }
}
