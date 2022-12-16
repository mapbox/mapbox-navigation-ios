import XCTest
import CarPlay
import TestHelper
import CarPlayTestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class CarPlayNavigationViewControllerTests: TestCase {
    
    func testTravelEstimates() {
        
        class MapTemplateMock: CPMapTemplate {
            
            var travelEstimates: CPTravelEstimates?
            
            var navigationSession: CPNavigationSession!
            
            override func update(_ estimates: CPTravelEstimates,
                                 for trip: CPTrip,
                                 with timeRemainingColor: CPTimeRemainingColor) {
                travelEstimates = estimates
            }
            
            override func startNavigationSession(for trip: CPTrip) -> CPNavigationSession {
                return navigationSession
            }
        }
        
        let navigationRouteOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 9.519172, longitude: 47.210823),
            CLLocationCoordinate2D(latitude: 9.52222, longitude: 47.214268),
            CLLocationCoordinate2D(latitude: 47.212326, longitude: 9.512569),
        ])
        
        let routeResponse = IndexedRouteResponse(routeResponse: Fixture.routeResponse(from: "multileg-route",
                                                                                      options: navigationRouteOptions),
                                                 routeIndex: 0)
        
        let navigationService = MapboxNavigationService(indexedRouteResponse: routeResponse,
                                                        customRoutingProvider: nil,
                                                        credentials: Fixture.credentials)
        
        let mapTemplateMock = MapTemplateMock()
        let navigationSession = CPNavigationSessionFake(maneuvers: [CPManeuver()])
        mapTemplateMock.navigationSession = navigationSession
        
        let interfaceController = FakeCPInterfaceController(context: #function)
        
        let carPlayManager = CarPlayManager(customRoutingProvider: MapboxRoutingProvider(.offline))
        
        let carPlayNavigationViewController = CarPlayNavigationViewController(navigationService: navigationService,
                                                                              mapTemplate: mapTemplateMock,
                                                                              interfaceController: interfaceController,
                                                                              manager: carPlayManager)
        let trip = CPTrip(origin: MKMapItem(),
                          destination: MKMapItem(),
                          routeChoices: [])
        carPlayNavigationViewController.startNavigationSession(for: trip)
        
        guard let firstCoordinate = navigationService.routeProgress.currentLeg.shape.coordinates.first else {
            XCTFail("First coordinate should be valid.")
            return
        }
        let userInfo: [RouteController.NotificationUserInfoKey: Any] = [
            .routeProgressKey: navigationService.routeProgress,
            .locationKey: CLLocation(latitude: firstCoordinate.latitude, longitude: firstCoordinate.longitude),
        ]
        let progressDidChangeNotification = NSNotification(name: .routeControllerProgressDidChange,
                                                           object: navigationService.router,
                                                           userInfo: userInfo)
        
        carPlayNavigationViewController.progressDidChange(progressDidChangeNotification)
        
        let distanceRemaining = Measurement(distance: navigationService.routeProgress.distanceRemaining).localized()
        let expectedTravelEstimates = CPTravelEstimates(distanceRemaining: distanceRemaining,
                                                        timeRemaining: navigationService.routeProgress.durationRemaining)
        let actualTravelEstimates = mapTemplateMock.travelEstimates
        
        XCTAssertEqual(actualTravelEstimates?.distanceRemaining.value,
                       expectedTravelEstimates.distanceRemaining.value,
                       "Remaining distances should be equal.")
        XCTAssertEqual(actualTravelEstimates?.timeRemaining,
                       expectedTravelEstimates.timeRemaining,
                       "Remaining times should be equal.")
    }
}
