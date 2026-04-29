@testable import MapboxNavigationCore
import XCTest

final class RerouteReasonTests: XCTestCase {
    func testRerouteReasonFromRouteReqiest() {
        let baseUrl = "https://example.com/directions"

        let allCases: [(reason: RerouteReason, param: String)] = [
            (.deviation, "deviation"),
            (.closure, "closure"),
            (.insufficientCharge, "insufficient_charge"),
            (.parametersChange, "parameters_change"),
            (.routeInvalidated, "route_invalidated"),
        ]

        for (expectedReason, param) in allCases {
            let url = "\(baseUrl)?reason=\(param)"
            let result = RerouteReason(routeRequest: url)
            XCTAssertEqual(result, expectedReason, "Failed for reason: \(param)")
        }

        XCTAssertNil(RerouteReason(routeRequest: "\(baseUrl)?reason=unexpected"))
        XCTAssertNil(RerouteReason(routeRequest: "\(baseUrl)?areason=unexpected"))
        XCTAssertNil(RerouteReason(routeRequest: baseUrl))
        XCTAssertNil(RerouteReason(routeRequest: "not an url"))
    }
}
