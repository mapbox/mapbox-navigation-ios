import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class ControlRouteTests: FBSnapshotTestCase {
    
    
    override func setUp() {
        super.setUp()
        route.accessToken = bogusToken
        recordMode = false
        isDeviceAgnostic = false
    }
    
    func testSimpleSnapping() {
        let bundle = Bundle(for: ControlRouteTests.self)
        let filePath = bundle.path(forResource: "SIMPLE_SNAP", ofType: "json")!
        let locations = Array<CLLocation>.locations(from: filePath)!
        
        let waypoints: [Waypoint] = [Waypoint(coordinate: locations.first!.coordinate),
                                     Waypoint(coordinate: locations.last!.coordinate)]
        
        let route = Fixture.route(from: "SIMPLE_SNAP.route", waypoints: waypoints)
        route.accessToken = bogusToken
        
        let view = PlotRoute(frame: CGRect(origin: .zero, size: CGSize(width: 2000, height: 800)))
        view.route = route
        view.rawLocations = locations
        FBSnapshotVerifyView(view)
    }
    
    func testSignalJumps() {
        let bundle = Bundle(for: ControlRouteTests.self)
        let filePath = bundle.path(forResource: "38512A3B-032C-452D-95EA-06C845B64780", ofType: "json")!
        let locations = Array<CLLocation>.locations(from: filePath)!
        
        let waypoints: [Waypoint] = [Waypoint(coordinate: locations.first!.coordinate),
                                     Waypoint(coordinate: locations.last!.coordinate)]
        
        let route = Fixture.route(from: "38512A3B-032C-452D-95EA-06C845B64780.route", waypoints: waypoints)
        route.accessToken = bogusToken
        
        let view = PlotRoute(frame: CGRect(origin: .zero, size: CGSize(width: 2000, height: 2000)))
        view.route = route
        view.rawLocations = locations
        FBSnapshotVerifyView(view)
    }
    
    func testRerouteSignalJumps() {
        let bundle = Bundle(for: ControlRouteTests.self)
        let filePath = bundle.path(forResource: "7E2DC0D0-50E9-406F-857C-77FDE0A14B67", ofType: "json")!
        let locations = Array<CLLocation>.locations(from: filePath)!
        
        let waypoints: [Waypoint] = [Waypoint(coordinate: locations.first!.coordinate),
                                     Waypoint(coordinate: locations.last!.coordinate)]
        
        let route = Fixture.route(from: "7E2DC0D0-50E9-406F-857C-77FDE0A14B67.route", waypoints: waypoints)
        route.accessToken = bogusToken
        
        let view = PlotRoute(frame: CGRect(origin: .zero, size: CGSize(width: 2000, height: 2000)))
        view.route = route
        view.rawLocations = locations
        FBSnapshotVerifyView(view)
    }
}
