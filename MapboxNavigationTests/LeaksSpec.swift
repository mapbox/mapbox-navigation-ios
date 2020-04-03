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
        
        return route
    }()
    
    lazy var initialOptions: RouteOptions = {
        guard case let .route(options) = response.options else {
            preconditionFailure("expecting route options")
        }
        return options
    }()
    
    lazy var dummySvc: NavigationService = MapboxNavigationService(route: self.initialRoute, routeOptions: initialOptions)
    
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
                let directions = DirectionsSpy(credentials: Fixture.credentials)
                let service = MapboxNavigationService(route: route, routeOptions: self.initialOptions, directions: directions, eventsManagerType: NavigationEventsManagerSpy.self)
                let navOptions = NavigationOptions(navigationService: service, voiceController: RouteVoiceControllerStub(navigationService: self.dummySvc))
                

                return NavigationViewController(for: route, routeOptions: self.initialOptions, navigationOptions: navOptions)
            }
            
            it("must not leak") {
                expect(navigationViewController).toNot(leak())
            }
        }
    }
}
