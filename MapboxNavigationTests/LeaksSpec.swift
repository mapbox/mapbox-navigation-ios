import XCTest
import Quick
import Nimble
import MapboxDirections
@testable import MapboxCoreNavigation
@testable import MapboxNavigation

class LeaksSpec: QuickSpec {
    
    lazy var initialRoute: Route = {
        let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String: Any]
        let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
        let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
        let route     = Route(json: jsonRoute, waypoints: [waypoint1, waypoint2], options: NavigationRouteOptions(waypoints: [waypoint1, waypoint2]))
        
        route.accessToken = "foo"
        
        return route
    }()
    
    override func spec() {
        describe("RouteVoiceController") {
            
            let voiceController = LeakTest {
                return RouteVoiceController()
            }
            
            let resumeNotifications: (RouteVoiceController) -> () = { controller in
                controller.resumeNotifications()
            }
            
            it("must not leak") {
                expect(voiceController).toNot(leakWhen(resumeNotifications))
            }
        }
        
        describe("NavigationViewController") {
            let route = initialRoute
            
            let navigationViewController = LeakTest {
                return NavigationViewController(for: route, voiceController: FakeVoiceController())
            }
            
            it("must not leak") {
                expect(navigationViewController).toNot(leak())
            }
        }
    }
}
