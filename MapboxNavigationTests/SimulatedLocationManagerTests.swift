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
        let route = Fixture.routesFromMatches(at: "sthlm-double-back", options: NavigationMatchOptions(coordinates: [
            .init(latitude: 59.337928, longitude: 18.076841),
            .init(latitude: 59.337661, longitude: 18.075897),
            .init(latitude: 59.337129, longitude: 18.075478),
            .init(latitude: 59.336866, longitude: 18.075273),
            .init(latitude: 59.336623, longitude: 18.075806),
            .init(latitude: 59.336391, longitude: 18.076943),
            .init(latitude: 59.338731, longitude: 18.079343),
            .init(latitude: 59.339058, longitude: 18.07774),
            .init(latitude: 59.338901, longitude: 18.076929),
            .init(latitude: 59.338333, longitude: 18.076467),
            .init(latitude: 59.338156, longitude: 18.075723),
            .init(latitude: 59.338311, longitude: 18.074968),
            .init(latitude: 59.33865, longitude: 18.074935),
        ]))![0]
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
}

class SimulatedLocationManagerSpy: NSObject, CLLocationManagerDelegate {
    var locations = [CLLocation]()
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locations.append(contentsOf: locations)
    }
}
