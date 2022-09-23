import Foundation
import XCTest
@testable import MapboxNavigation
@testable import MapboxCoreNavigation
import TestHelper
import MapboxDirections

final class LeaksTests: TestCase {
    var initialOptions: RouteOptions {
        guard case let .route(options) = response.options else {
            preconditionFailure("expecting route options")
        }
        return options
    }

    func testUserCourseViewLeak() {
        let leakTester = LeakTest {
            UserPuckCourseView(frame: .zero)
        }
        XCTAssertFalse(leakTester.isLeaking())
    }

    func testRouteVoiceController() {
        let dummySvc = MapboxNavigationService(indexedRouteResponse: IndexedRouteResponse(routeResponse: response,
                                                                                          routeIndex: 0),
                                               customRoutingProvider: nil,
                                               credentials: Fixture.credentials)

        let leakTester = LeakTest {
            let routeVoiceController = RouteVoiceController(navigationService: dummySvc,
                                                            accessToken: .mockedAccessToken)
            routeVoiceController.observeNotifications(by: dummySvc)
            return routeVoiceController
        }

        XCTAssertFalse(leakTester.isLeaking())
    }

    func testNavigationViewController() {
        let leakTester = LeakTest {
            let indexedRouteResponse = IndexedRouteResponse(routeResponse: response,
                                                            routeIndex: 0)
            let service = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                  customRoutingProvider: MapboxRoutingProvider(.offline),
                                                  credentials: Fixture.credentials,
                                                  eventsManagerType: NavigationEventsManagerSpy.self)
            let navOptions = NavigationOptions(navigationService: service, voiceController:
                                                RouteVoiceControllerStub(navigationService: service))

            return NavigationViewController(for: indexedRouteResponse,
                                            navigationOptions: navOptions)
        }
        XCTAssertFalse(leakTester.isLeaking())
    }
}
