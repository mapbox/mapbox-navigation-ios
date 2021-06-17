@testable import MapboxNavigation
@testable import MapboxCoreNavigation
import MapboxDirections
import XCTest
import Foundation
import TestHelper
import CarPlay
import CarPlayTestHelper

@available(iOS 12.0, *)
fileprivate class CarPlayNavigationViewControllerDelegateSpy: NSObject, CarPlayNavigationViewControllerDelegate {
    var didArriveExpectation: XCTestExpectation!
    
    init(_ didArriveExpectation: XCTestExpectation) {
        self.didArriveExpectation = didArriveExpectation
    }
    
    func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController, shouldPresentArrivalUIFor waypoint: Waypoint) -> Bool {
        return true
    }
}

@available(iOS 12.0, *)
fileprivate class CPManeuverFake: CPManeuver {
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 12.0, *)
class CarPlayNavigationViewControllerTests: XCTestCase {
    func testCarplayDisplaysCorrectEstimates() {
        //set up the litany of dependancies
        let directions = Directions(credentials: Fixture.credentials)
        let manager = CarPlayManager(directions: directions)
        let options = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 9.519172, longitude: 47.210823),
            CLLocationCoordinate2D(latitude: 9.52222, longitude: 47.214268),
            CLLocationCoordinate2D(latitude: 47.212326, longitude: 9.512569),
        ])
        let route = Fixture.route(from: "multileg-route", options: options)
        let navService = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: options, directions: .mocked)
        let interface = FakeCPInterfaceController(context: "test estimates display")
        let mapSpy = MapTemplateSpy()
        let trip = CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [])
        let fakeManeuver = CPManeuverFake()
        let fakeSession = CPNavigationSessionFake(maneuvers: [fakeManeuver])
        mapSpy.fakeSession = fakeSession
        let progress = navService.routeProgress
        let firstCoordinate = progress.currentLeg.shape.coordinates.first!
        let location = CLLocation(latitude: firstCoordinate.latitude, longitude: firstCoordinate.longitude)
        
        //create the subject and notification
        let subject = CarPlayNavigationViewController(navigationService: navService, mapTemplate: mapSpy, interfaceController: interface, manager: manager)
        subject.startNavigationSession(for: trip)
        let payload: [RouteController.NotificationUserInfoKey: Any] = [
            .routeProgressKey: navService.routeProgress,
            .locationKey: location,
        ]
        let fakeNotication = NSNotification(name: .routeControllerProgressDidChange, object: navService.router, userInfo: payload)
        
        //fire the fake notification
        subject.progressDidChange(fakeNotication)
        
        //retreieve the update
        guard let update = mapSpy.estimatesUpdate else {
            XCTFail("The CPNVC needs to update the map template with new estimates when it recieves a progress update.")
            return
        }
        
        // establish a point of truth and fetch the answer from the update
        let distanceTruth = Measurement(distance: progress.distanceRemaining).localized()
        let estimateTruth = CPTravelEstimates(distanceRemaining: distanceTruth, timeRemaining: progress.durationRemaining)
        let answer = update.0
        
        //verify answer is correct
        let distanceEqual = answer.distanceRemaining.value == estimateTruth.distanceRemaining.value
        let timeEqual = answer.timeRemaining.doubleValue == estimateTruth.timeRemaining.doubleValue
        XCTAssert(distanceEqual && timeEqual, "The subject should update the CP Map Template based upon CPTravelEstimates derived from the entire route progress.")
    }
}
