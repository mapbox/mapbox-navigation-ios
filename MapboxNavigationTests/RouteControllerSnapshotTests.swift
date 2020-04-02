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
        let options = NavigationMatchOptions(coordinates: [
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
        ])
        let route = Fixture.routesFromMatches(at: "sthlm-double-back", options: options)![0]
        
        let bundle = Bundle(for: RouteControllerSnapshotTests.self)
        let filePath = bundle.path(forResource: "sthlm-double-back-replay", ofType: "json")
        
        let locations = Array<CLLocation>.locations(from: filePath!)
        let locationManager = ReplayLocationManager(locations: locations)
        replayManager = locationManager
        locationManager.startDate = Date()
        let equivalentRouteOptions = NavigationRouteOptions(navigationMatchOptions: options)
        let routeController = RouteController(along: route, options: equivalentRouteOptions, dataSource: self)
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
