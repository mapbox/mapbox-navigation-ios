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
        let dummySvc = MapboxNavigationService(routeResponse: response,
                                               routeIndex: 0,
                                               routeOptions: initialOptions,
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
            let service = MapboxNavigationService(routeResponse: response,
                                                  routeIndex: 0,
                                                  routeOptions: self.initialOptions,
                                                  customRoutingProvider: MapboxRoutingProvider(.offline),
                                                  credentials: Fixture.credentials,
                                                  eventsManagerType: NavigationEventsManagerSpy.self)
            let navOptions = NavigationOptions(navigationService: service, voiceController:
                                                RouteVoiceControllerStub(navigationService: service))

            return NavigationViewController(for: response,
                                               routeIndex: 0,
                                               routeOptions: self.initialOptions,
                                               navigationOptions: navOptions)
        }
        XCTAssertFalse(leakTester.isLeaking())
    }
}
