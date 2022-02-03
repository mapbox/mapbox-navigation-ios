@testable import MapboxNavigation
@testable import MapboxCoreNavigation
import MapboxDirections
import XCTest
import Foundation
import TestHelper
import CarPlay
import CarPlayTestHelper

@available(iOS 12.0, *)
class CarPlayNavigationViewControllerTests: TestCase {
    
    func testTravelEstimates() {
        let navigationRouteOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 9.519172, longitude: 47.210823),
            CLLocationCoordinate2D(latitude: 9.52222, longitude: 47.214268),
            CLLocationCoordinate2D(latitude: 47.212326, longitude: 9.512569),
        ])
        
        let routeResponse = Fixture.routeResponse(from: "multileg-route",
                                                  options: navigationRouteOptions)
        
        let navigationService = MapboxNavigationService(routeResponse: routeResponse,
                                                        routeIndex: 0,
                                                        routeOptions: navigationRouteOptions)
        
        let mapTemplate = MapTemplateSpy()
        let navigationSession = CPNavigationSessionFake(maneuvers: [CPManeuver()])
        mapTemplate.fakeSession = navigationSession
        
        let interfaceController = FakeCPInterfaceController(context: #function)
        
        let carPlayManager = CarPlayManager(routingProvider: MapboxRoutingProvider(.offline))
        
        let carPlayNavigationViewController = CarPlayNavigationViewController(navigationService: navigationService,
                                                                              mapTemplate: mapTemplate,
                                                                              interfaceController: interfaceController,
                                                                              manager: carPlayManager)
        let trip = CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [])
        carPlayNavigationViewController.startNavigationSession(for: trip)
        
        guard let firstCoordinate = navigationService.routeProgress.currentLeg.shape.coordinates.first else {
            XCTFail("First coorindate should be valid.")
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
        let actualTravelEstimates = mapTemplate.estimatesUpdate?.0
        
        XCTAssertEqual(actualTravelEstimates?.distanceRemaining.value,
                       expectedTravelEstimates.distanceRemaining.value,
                       "Remaining distances should be equal.")
        XCTAssertEqual(actualTravelEstimates?.timeRemaining.doubleValue,
                       expectedTravelEstimates.timeRemaining.doubleValue,
                       "Remaining times should be equal.")
    }
}
