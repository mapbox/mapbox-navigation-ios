import Foundation
import XCTest
import TestHelper
import MapboxCoreNavigation
@testable import MapboxNavigation
import CoreLocation

final class EndOfRouteFeedbackTests: TestCase {
    func testDisableFeedback() {
        let startLocation = CLLocationCoordinate2D(latitude: 32.714719, longitude: -117.149368)
        let endLocation = CLLocationCoordinate2D(latitude: 32.714721,
                                                 longitude: -117.149314)

        let route = Fixture.route(between: startLocation, and: endLocation)
        let options = NavigationRouteOptions(coordinates: [startLocation, endLocation])
        let service = MapboxNavigationService(routeResponse: route.response,
                                              routeIndex: 0,
                                              routeOptions: options,
                                              routingProvider: MapboxRoutingProvider(.offline),
                                              credentials: Fixture.credentials,
                                              locationSource: nil,
                                              eventsManagerType: nil,
                                              simulating: .never,
                                              routerType: nil)

        let viewController = NavigationViewController(navigationService: service)
        viewController.showsEndOfRouteFeedback = false
        XCTAssertFalse(viewController.showsEndOfRouteFeedback)
        _ = viewController.view
        XCTAssertFalse(viewController.showsEndOfRouteFeedback)
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        guard let arrivalController = viewController.arrivalController else {
            XCTFail("Arrival controller should load after view is loaded"); return
        }

        guard let endOfRouteView = arrivalController.navigationViewData.navigationView.endOfRouteView else {
            return
        }

        XCTAssertTrue(endOfRouteView.isHidden)
    }
}
