import XCTest
import Turf
import MapboxDirections
@testable import MapboxCoreNavigation
#if !SWIFT_PACKAGE
import TestHelper

class RouteControllerTests: XCTestCase {
    var replayManager: ReplayLocationManager?

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        replayManager = nil
        super.tearDown()
    }
    
    func testRouteSnappingOvershooting() {
        let coordinates:[CLLocationCoordinate2D] = [
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
        ]
        let options = NavigationMatchOptions(coordinates: coordinates)
        let route = Fixture.routesFromMatches(at: "sthlm-double-back", options: options)![0]
        
        let locations = Array<CLLocation>.locations(from: "sthlm-double-back-replay")
        let locationManager = ReplayLocationManager(locations: locations)
        replayManager = locationManager
        locationManager.startDate = Date()
        let equivalentRouteOptions = NavigationRouteOptions(navigationMatchOptions: options)
        let routeController = RouteController(along: route, routeIndex: 0, options: equivalentRouteOptions, directions: DirectionsSpy(), dataSource: self)
        locationManager.delegate = routeController
        
        var testCoordinates = [CLLocationCoordinate2D]()
        
        while testCoordinates.count < locationManager.locations.count {
            locationManager.tick()
            testCoordinates.append(routeController.location!.coordinate)
        }
        
        let expectedCoordinates = locations.map{$0.coordinate}
        XCTAssert(expectedCoordinates == testCoordinates)
    }
}

extension RouteControllerTests: RouterDataSource {
    var location: CLLocation? {
        return replayManager?.location
    }
    
    var locationProvider: NavigationLocationManager.Type {
        return NavigationLocationManager.self
    }
}
#endif
