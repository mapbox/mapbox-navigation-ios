import XCTest
import Quick
import Nimble
import MapboxDirections
import MapboxMaps
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
    
    lazy var dummySvc: NavigationService = MapboxNavigationService(route: self.initialRoute, routeIndex: 0, routeOptions: initialOptions, directions: .mocked)
    
    override func spec() {
        describe("RouteVoiceController") {
            let voiceController = LeakTest {
                return RouteVoiceController(navigationService: self.dummySvc, accessToken: .mockedAccessToken)
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
            ResourceOptionsManager.default.resourceOptions.accessToken = .mockedAccessToken

            let navigationViewController = LeakTest {
                let directions = DirectionsSpy(credentials: Fixture.credentials)
                let service = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: self.initialOptions, directions: directions, eventsManagerType: NavigationEventsManagerSpy.self)
                let navOptions = NavigationOptions(navigationService: service, voiceController: RouteVoiceControllerStub(navigationService: self.dummySvc))
                

                return NavigationViewController(for: route, routeIndex: 0, routeOptions: self.initialOptions, navigationOptions: navOptions)
            }
            
            it("must not leak") {
                expect(navigationViewController).toNot(leak())
            }
        }
    }
}
