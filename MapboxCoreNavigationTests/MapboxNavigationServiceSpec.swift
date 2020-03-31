import XCTest
import Quick
import Nimble
import MapboxDirections
import TestHelper
@testable import MapboxCoreNavigation

class MapboxNavigationServiceSpec: QuickSpec {
    lazy var initialRoute: Route = {
        let route     = response.routes!.first!
        return route
    }()
    
    override func spec() {
        describe("MapboxNavigationService") {
            let route = initialRoute
            
            let subject = LeakTest {
                let service = MapboxNavigationService(route: route, routeOptions: routeOptions,  directions: DirectionsSpy())
                return service
            }
            it("Must not leak.") {
                expect(subject).toNot(leak())
            }
        }
    }
}
