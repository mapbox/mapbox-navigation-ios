@testable import MapboxNavigation
@testable import MapboxCoreNavigation
import MapboxDirections
import XCTest
import Foundation
import TestHelper


@available(iOS 12.0, *)
fileprivate class CarPlayNavigationDelegateSpy: NSObject, CarPlayNavigationDelegate {
    var didArriveExpectation: XCTestExpectation!
    
    init(_ didArriveExpectation: XCTestExpectation) {
        self.didArriveExpectation = didArriveExpectation
    }
    
    func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController, didArriveAt waypoint: Waypoint) -> Bool
    {
        self.didArriveExpectation.fulfill()
        return true
    }
}

@available(iOS 12.0, *)
class CarPlayNavigationViewControllerTests: XCTestCase {
    
    
    
    func testArrive() {
        let expectation = XCTestExpectation(description: "The delegate should of recieved the didArrive message")
        let spy = CarPlayNavigationDelegateSpy(expectation)
        
        let route = Fixture.route(from: "routeWithInstructions")
        let serviceFake = MapboxNavigationService(route: route)
        let fakeTemplate = CPMapTemplate()
        let fakeManager = CarPlayManager(styles: nil, directions: nil, eventsManager: nil)
        simulateCarPlayConnection(fakeManager)
        let subject = CarPlayNavigationViewController(navigationService: serviceFake, mapTemplate: fakeTemplate, interfaceController: fakeManager.interfaceController!, manager: fakeManager)
        subject.carPlayNavigationDelegate = spy
        let answer = subject.navigationService(serviceFake, didArriveAt: route.routeOptions.waypoints.last!)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssert(answer == true, "Boolean response not respected in didArrive: delegate call")
    }

}
