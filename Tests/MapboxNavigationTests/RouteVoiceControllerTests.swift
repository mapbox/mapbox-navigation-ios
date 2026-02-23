import XCTest
import MapboxDirections
@testable import MapboxCoreNavigation
import TestHelper
import CoreLocation
@testable import MapboxNavigation

class RouteVoiceControllerTests: TestCase {
    var routeVoiceController: RouteVoiceController!
    var speechSynthesizerStub: SpeechSynthesizerStub!

    var navigationRouteOptions: NavigationRouteOptions {
        let options = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 40.311012, longitude: -112.47926),
            CLLocationCoordinate2D(latitude: 29.99908, longitude: -102.828197),
        ])
        options.shapeFormat = .polyline
        return options
    }
    var routeResponse: RouteResponse {
        return Fixture.routeResponse(from: "route-with-instructions", options: navigationRouteOptions)
    }
    var indexedRouteResponse: IndexedRouteResponse {
        IndexedRouteResponse(routeResponse: Fixture.routeResponse(from: "route-with-instructions",
                                                                  options: navigationRouteOptions),
                             routeIndex: 0)
    }
    
    override func setUp() {
        super.setUp()

        speechSynthesizerStub = SpeechSynthesizerStub()
        let dummyService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                   customRoutingProvider: nil,
                                                   credentials: Fixture.credentials)
        routeVoiceController = RouteVoiceController(navigationService: dummyService,
                                                    speechSynthesizer: speechSynthesizerStub)
    }

    func testDidRerouteIfShouldPlayRerouteSoundKeyAndNotMuted() {
        routeVoiceController.didReroute(notification: notification(with: true))
        XCTAssertTrue(speechSynthesizerStub.stopSpeakingCalled)
    }

    func testDidRerouteIfShouldPlayRerouteSoundKeyAndMuted() {
        routeVoiceController.playRerouteSound = false
        routeVoiceController.didReroute(notification: notification(with: true))
        XCTAssertFalse(speechSynthesizerStub.stopSpeakingCalled)
    }

    func testDidRerouteIfShouldNotPlayRerouteSoundKeyAndNotMuted() {
        routeVoiceController.didReroute(notification: notification(with: false))
        XCTAssertFalse(speechSynthesizerStub.stopSpeakingCalled)
    }

    private func notification(with shouldPlayRerouteSound: Bool) -> NSNotification {
        let userInfo: [AnyHashable : Any] = [
            RouteController.NotificationUserInfoKey.shouldPlayRerouteSoundKey: shouldPlayRerouteSound
        ]
        return NSNotification(name: .routeControllerDidReroute,
                              object: nil,
                              userInfo: userInfo)
    }
}
