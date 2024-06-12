import Combine
import Foundation
import MapboxDirections
@testable import MapboxNavigationUIKit
import XCTest
@_spi(MapboxInternal) @testable import MapboxNavigationCore
import TestHelper

final class LeaksTests: TestCase {
    @MainActor
    func testRouteVoiceController() async {
        let routeProgressPublisher: CurrentValueSubject<RouteProgressState?, Never> = .init(nil)
        let rerouteStartedPublisher: PassthroughSubject<Void, Never> = .init()
        let fasterRouteSetPublisher: PassthroughSubject<Void, Never> = .init()
        let speechSynthesizer = SpeechSynthesizerStub()
        let routes = await Fixture.navigationRoutes(from: "route", options: routeOptions)

        let leakTester = LeakTest {
            let routeVoiceController = RouteVoiceController(
                routeProgressing: routeProgressPublisher.eraseToAnyPublisher(),
                rerouteStarted: rerouteStartedPublisher.eraseToAnyPublisher(),
                fasterRouteSet: fasterRouteSetPublisher.eraseToAnyPublisher(),
                speechSynthesizer: speechSynthesizer
            )
            rerouteStartedPublisher.send()
            fasterRouteSetPublisher.send()
            let routeProgress = RouteProgress(
                navigationRoutes: routes,
                waypoints: [],
                congestionConfiguration: .default
            )
            routeProgressPublisher.send(RouteProgressState(routeProgress: routeProgress))
            return routeVoiceController
        }

        XCTAssertFalse(leakTester.isLeaking())
    }

    @MainActor
    func testNavigationViewController() async {
        let routes = await Fixture.navigationRoutes(from: "route", options: routeOptions)

        let navigationProvider = navigationProvider!
        let leakTester = LeakTest {
            let options = NavigationOptions(
                mapboxNavigation: navigationProvider,
                voiceController: navigationProvider.routeVoiceController,
                eventsManager: navigationProvider.eventsManager()
            )

            return NavigationViewController(navigationRoutes: routes, navigationOptions: options)
        }
        XCTAssertFalse(leakTester.isLeaking())
    }
}
