import XCTest
import Quick
import Nimble
import MapboxDirections
import TestHelper
@testable import MapboxCoreNavigation

class MapboxNavigationServiceSpec: QuickSpec {
    
    lazy var initialRoute: Route = {
        let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String: Any]
        let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
        let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
        let route     = Route(json: jsonRoute, waypoints: [waypoint1, waypoint2], options: NavigationRouteOptions(waypoints: [waypoint1, waypoint2]))
        
        route.accessToken = "foo"
        
        return route
    }()
    
    override func spec() {
        describe("MapboxNavigationService") {
            let route = initialRoute
            
            let subject = LeakTest {
                let service = MapboxNavigationService(route: route, directions: DirectionsSpy(accessToken: "deadbeef"))
                return service
            }
            it("Must not leak.") {
                expect(subject).toNot(leak())
            }
        }
    }
}
