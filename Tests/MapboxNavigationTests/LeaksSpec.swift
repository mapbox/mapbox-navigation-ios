import XCTest
import Quick
import Nimble
import MapboxMaps
@testable import TestHelper
@testable import MapboxCoreNavigation
@testable import MapboxNavigation
@testable import MapboxDirections

class LeaksSpec: QuickSpec {
    
    lazy var initialOptions: RouteOptions = {
        guard case let .route(options) = response.options else {
            preconditionFailure("expecting route options")
        }
        return options
    }()
    
    lazy var dummySvc: NavigationService = MapboxNavigationService(routeResponse: response, routeIndex: 0, routeOptions: initialOptions, directions: .mocked)
    
    override func spec() {
        DirectionsCredentials.injectSharedToken(.mockedAccessToken)

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
            ResourceOptionsManager.default.resourceOptions.accessToken = .mockedAccessToken

            let navigationViewController = LeakTest {
                let directions = DirectionsSpy(credentials: Fixture.credentials)
                let service = MapboxNavigationService(routeResponse: response, routeIndex: 0, routeOptions: self.initialOptions, directions: directions, eventsManagerType: NavigationEventsManagerSpy.self)
                let navOptions = NavigationOptions(navigationService: service, voiceController: RouteVoiceControllerStub(navigationService: self.dummySvc))
                

                return NavigationViewController(for: response, routeIndex: 0, routeOptions: self.initialOptions, navigationOptions: navOptions)
            }
            
            it("must not leak") {
                expect(navigationViewController).toNot(leak())
            }
        }
    }
}
