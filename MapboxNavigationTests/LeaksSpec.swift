import XCTest
import Quick
import Nimble
import MapboxDirections
@testable import TestHelper
@testable import MapboxCoreNavigation
@testable import MapboxNavigation

class LeaksSpec: QuickSpec {
    lazy var initialRoute: Route = {
        let route = response.routes!.first!
        route.accessToken = "foo"
        
        return route
    }()
    
    lazy var dummySvc: NavigationService = MapboxNavigationService(route: self.initialRoute)
    
    override func spec() {
        describe("RouteVoiceController") {
            let voiceController = LeakTest {
                return RouteVoiceController(navigationService: self.dummySvc)
            }
            
            let resumeNotifications: (RouteVoiceController) -> () = { controller in
                controller.observeNotifications(by: self.dummySvc)
            }
            
            it("must not leak") {
                expect(voiceController).toNot(leakWhen(resumeNotifications))
            }
        }
        
        describe("NavigationViewController") {
            let route = initialRoute
            
            let navigationViewController = LeakTest {
                let directions = DirectionsSpy(accessToken: "deadbeef")
                let service = MapboxNavigationService(route: route, directions: directions, eventsManagerType: NavigationEventsManagerSpy.self)
                let options = NavigationOptions(navigationService: service, voiceController: RouteVoiceControllerStub(navigationService: self.dummySvc))
                return NavigationViewController(for: route, options: options)
            }
            
            it("must not leak") {
                expect(navigationViewController).toNot(leak())
            }
        }
    }
}
