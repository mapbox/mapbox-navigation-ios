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
    
    func testControlFirstRoute() {
        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 42.361634, longitude: -71.12852),
            CLLocationCoordinate2D(latitude: 42.352396, longitude: -71.068719)
        ])
        
        let route = Fixture.route(from: "PipeFittersUnion-FourSeasonsBoston", options: routeOptions)
        let trace = Fixture.locations(from: "PipeFittersUnion-FourSeasonsBoston.trace")
        
        let locationManager = ReplayLocationManager(locations: trace)
        _ = navigationViewController(route: route, routeIndex: 0, routeOptions: routeOptions, locationManager: locationManager)
        
        locationManager.tick()
        
        measure {
            while locationManager.currentIndex > 0 {
                locationManager.tick()
            }
        }
    }
    
    func testControlSecondRoute() {
        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 38.853108, longitude: -77.043331),
            CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906)
        ])
        
        let route = Fixture.route(from: "DCA-Arboretum", options: routeOptions)
        let trace = Fixture.locations(from: "DCA-Arboretum.trace")
        
        let locationManager = ReplayLocationManager(locations: trace)
        _ = navigationViewController(route: route, routeIndex: 0, routeOptions: routeOptions, locationManager: locationManager)
        
        locationManager.tick()
        
        measure {
            while locationManager.currentIndex > 0 {
                locationManager.tick()
            }
        }
    }
    
    func navigationViewController(route: Route, routeIndex: Int, routeOptions: NavigationRouteOptions, locationManager: ReplayLocationManager) -> NavigationViewController {
        let directions = DirectionsSpy()
        let service = MapboxNavigationService(route: route, routeIndex: 0,
                                              routeOptions: routeOptions,
                                              directions: directions,
                                              locationSource: locationManager,
                                              eventsManagerType: NavigationEventsManagerSpy.self,
                                              simulating: .never,
                                              routerType: RouteController.self)
        let speechSynthesizer = SpeechSynthesizerSpy()
        let voiceController = RouteVoiceController(navigationService: service, speechSynthesizer: speechSynthesizer, accessToken: token)
        
        let navigationOptions = NavigationOptions(navigationService: service, voiceController: voiceController)
        
        let navigationViewController = NavigationViewController(for: route, routeIndex: routeIndex, routeOptions: routeOptions, navigationOptions: navigationOptions)
        return navigationViewController
    }
}
