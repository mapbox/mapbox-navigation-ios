import XCTest
import FBSnapshotTestCase
import TestHelper
import MapboxDirections
@testable import MapboxCoreNavigation
@testable import MapboxNavigation


class SimulatedLocationManagerTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        recordMode = false
        agnosticOptions = [.OS, .device]
    }

    func testSimulateRouteDoublesBack() {
        let route = Fixture.routesFromMatches(at: "sthlm-double-back")![0]
        let locationManager = SimulatedLocationManager(route: route)
        let locationManagerSpy = SimulatedLocationManagerSpy()
        locationManager.delegate = locationManagerSpy
        locationManager.speedMultiplier = 5
        
        while locationManager.currentDistance < route.distance {
            locationManager.tick()
        }
        
        locationManager.delegate = nil
        
        let view = NavigationPlotter(frame: CGRect(origin: .zero, size: CGSize(width: 1000, height: 1000)))
        view.routePlotters = [RoutePlotter(route: route)]
        view.locationPlotters = [LocationPlotter(locations: locationManagerSpy.locations, color: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 0.5043463908), drawIndexesAsText: true)]
        
        verify(view)
    }
    
    func testTimerMechanism() {
        let now: DispatchTime = .now()
        var later: DispatchTime? = nil
        let expectation = XCTestExpectation(description: "Timer Fire")
        
        let timer = DispatchTimer(countdown: .milliseconds(1000)) {
            later = .now()
            expectation.fulfill()
        }
        timer.arm()
        wait(for: [expectation], timeout: 2)
        
        
        let notTooLittle = now + .milliseconds(700) < later ?? DispatchTime(uptimeNanoseconds: 0)
        let notTooMuch = now + .milliseconds(1400) > later ?? .distantFuture
        XCTAssert(notTooLittle, "Not enough time elapsed")
        XCTAssert(notTooMuch, "Too much time elapsed.")
    }
}

class SimulatedLocationManagerSpy: NSObject, CLLocationManagerDelegate {
    var locations = [CLLocation]()
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locations.append(contentsOf: locations)
    }
}
