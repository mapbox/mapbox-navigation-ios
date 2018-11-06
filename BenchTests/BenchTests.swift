import XCTest
import TestHelper
@testable import MapboxCoreNavigation
@testable import MapboxNavigation
@testable import Bench


class BenchTests: XCTestCase, CLLocationManagerDelegate {
    
    func testControlRoute1() {
        
        let token = "deadbeef"
        let route = Fixture.route(from: "DCA-Arboretum-Tunnels-1")
        let trace = Fixture.locations(from: "DCA-Arboretum-Tunnels-1.trace")
        
        let speechAPI = SpeechAPISpy(accessToken: token)
        let voiceController = MapboxVoiceController(speechClient: speechAPI, audioPlayerType: AudioPlayerDummy.self)
        let locationManager = ReplayLocationManager(locations: trace)
        let directions = DirectionsSpy(accessToken: token)
        let service = MapboxNavigationService(route: route,
                                              directions: directions,
                                              locationSource: locationManager,
                                              eventsManagerType: NavigationEventsManagerSpy.self,
                                              simulating: .never,
                                              routerType: nil)
        _ = NavigationViewController(for: route, navigationService: service, voiceController: voiceController)
        
        locationManager.tick()
        
        measure {
            while locationManager.currentIndex > 0 {
                locationManager.tick()
            }
        }
    }
}

