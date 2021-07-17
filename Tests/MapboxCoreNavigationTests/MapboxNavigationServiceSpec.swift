import XCTest
import Quick
import Nimble
import MapboxDirections
import TestHelper
@testable import MapboxCoreNavigation

class MapboxNavigationServiceSpec: QuickSpec {
    override func spec() {
        describe("MapboxNavigationService") {
            let subject = LeakTest {
                let service = MapboxNavigationService(routeResponse: response, routeIndex: 0, routeOptions: routeOptions,  directions: DirectionsSpy())
                return service
            }
            it("Must not leak.") {
                expect(subject).toNot(leak())
            }
        }
    }
}
