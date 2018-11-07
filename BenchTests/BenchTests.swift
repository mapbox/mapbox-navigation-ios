import XCTest
import TestHelper
import MapboxDirections
@testable import MapboxCoreNavigation
@testable import MapboxNavigation
@testable import Bench


class BenchTests: XCTestCase, CLLocationManagerDelegate {
    
    let token = "deadbeef"
    
    override func setUp() {
        super.setUp()
        MGLAccountManager.accessToken = token
    }
    
    func testControlRoute1() {
        
        let route = Fixture.route(from: "PipeFittersUnion-FourSeasonsBoston")
        let trace = Fixture.locations(from: "PipeFittersUnion-FourSeasonsBoston.trace")
        
        let locationManager = ReplayLocationManager(locations: trace)
        _ = navigationViewController(route: route, locationManager: locationManager)
        
        locationManager.tick()
        
        measure {
            while locationManager.currentIndex > 0 {
                locationManager.tick()
            }
        }
    }
    
    func testControlRoute2() {
        
        let route = Fixture.route(from: "DCA-Arboretum")
        let trace = Fixture.locations(from: "DCA-Arboretum.trace")
        
        let locationManager = ReplayLocationManager(locations: trace)
        _ = navigationViewController(route: route, locationManager: locationManager)
        
        locationManager.tick()
        
        measure {
            while locationManager.currentIndex > 0 {
                locationManager.tick()
            }
        }
    }
    
    func navigationViewController(route: Route, locationManager: ReplayLocationManager) -> NavigationViewController {
        
        let speechAPI = SpeechAPISpy(accessToken: token)
        let voiceController = MapboxVoiceController(speechClient: speechAPI, audioPlayerType: AudioPlayerDummy.self)
        let directions = DirectionsSpy(accessToken: token)
        let service = MapboxNavigationService(route: route,
                                              directions: directions,
                                              locationSource: locationManager,
                                              eventsManagerType: NavigationEventsManagerSpy.self,
                                              simulating: .never,
                                              routerType: PortableRouteController.self)
        
        return NavigationViewController(for: route, navigationService: service, voiceController: voiceController)
    }
}


