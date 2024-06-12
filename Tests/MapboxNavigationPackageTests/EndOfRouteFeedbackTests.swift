import CoreLocation
import Foundation
import MapboxNavigationCore
@testable import MapboxNavigationUIKit
import TestHelper
import XCTest

@MainActor
final class EndOfRouteFeedbackTests: TestCase {
    func testDisableFeedback() async {
        let startLocation = CLLocationCoordinate2D(latitude: 32.714719, longitude: -117.149368)
        let endLocation = CLLocationCoordinate2D(latitude: 32.714721, longitude: -117.149314)

        let routes = await Fixture.navigationRoutes(between: startLocation, and: endLocation)
        let mapboxNavigation = navigationProvider.mapboxNavigation
        let viewController = NavigationViewController(
            navigationRoutes: routes,
            navigationOptions: .init(
                mapboxNavigation: mapboxNavigation,
                voiceController: navigationProvider.routeVoiceController,
                eventsManager: navigationProvider.eventsManager()
            )
        )
        viewController.showsEndOfRouteFeedback = false
        XCTAssertFalse(viewController.showsEndOfRouteFeedback)
        _ = viewController.view
        XCTAssertFalse(viewController.showsEndOfRouteFeedback)

        wait()

        guard let arrivalController = viewController.arrivalController else {
            XCTFail("Arrival controller should load after view is loaded"); return
        }

        guard let endOfRouteView = arrivalController.navigationViewData?.navigationView.endOfRouteView else {
            return
        }

        XCTAssertTrue(endOfRouteView.isHidden)
    }

    func wait(timeout: TimeInterval = 0.1) {
        let waitExpectation = expectation(description: "Wait expectation.")
        _ = XCTWaiter.wait(for: [waitExpectation], timeout: timeout)
    }
}
