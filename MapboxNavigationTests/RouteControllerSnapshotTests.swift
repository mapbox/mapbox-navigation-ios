import XCTest
import FBSnapshotTestCase
import Turf
import MapboxDirections
import TestHelper
@testable import MapboxCoreNavigation
@testable import MapboxNavigation


class RouteControllerSnapshotTests: FBSnapshotTestCase {

    var replayManager: ReplayLocationManager?

    override func setUp() {
        super.setUp()
        recordMode = false
        agnosticOptions = [.OS, .device]
    }

    override func tearDown() {
        replayManager = nil
        super.tearDown()
    }
    
    func testRouteSnappingOvershooting() {
        let route = Fixture.routesFromMatches(at: "sthlm-double-back")![0]
        
        let bundle = Bundle(for: RouteControllerSnapshotTests.self)
        let filePath = bundle.path(forResource: "sthlm-double-back-replay", ofType: "json")
        let jsonData = try! Data(contentsOf: URL(fileURLWithPath: filePath!))
        
        let jsonLocations = try! JSONSerialization.jsonObject(with: jsonData, options: []) as! [[String: Any]]
        let locations = jsonLocations.map { CLLocation(dictionary: $0) }
        let locationManager = ReplayLocationManager(locations: locations)
        replayManager = locationManager
        locationManager.startDate = Date()
        let routeController = RouteController(along: route, dataSource: self)
        locationManager.delegate = routeController
        
        var snappedLocations = [CLLocation]()
        
        while snappedLocations.count < locationManager.locations.count {
            locationManager.tick()
            snappedLocations.append(routeController.location!)
        }
        
        let view = NavigationPlotter(frame: CGRect(origin: .zero, size: CGSize(width: 1000, height: 1000)))
        view.routePlotters = [RoutePlotter(route: route)]
        view.locationPlotters = [LocationPlotter(locations: locations, color: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 0.5043463908), drawIndexesAsText: true),
                                 LocationPlotter(locations: snappedLocations, color: #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 0.3969795335), drawIndexesAsText: true)]
        
        verify(view)
    }
}

extension RouteControllerSnapshotTests: RouterDataSource {
    var location: CLLocation? {
        return replayManager?.location
    }
    
    var locationProvider: NavigationLocationManager.Type {
        return NavigationLocationManager.self
    }
}
