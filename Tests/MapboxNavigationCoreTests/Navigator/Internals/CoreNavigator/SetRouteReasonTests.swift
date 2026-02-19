@testable import MapboxNavigationCore
import MapboxNavigationNative_Private
import XCTest

final class SetRouteReasonTests: XCTestCase {
    func testNavNativeValue() {
        XCTAssertEqual(setRouteReason.reroute(nil).navNativeValue, .reroute)
        XCTAssertEqual(setRouteReason.reroute(.deviation).navNativeValue, .reroute)
        XCTAssertEqual(setRouteReason.reroute(.routeInvalidated).navNativeValue, .reroute)
        XCTAssertEqual(setRouteReason.newRoute.navNativeValue, .newRoute)
        XCTAssertEqual(setRouteReason.alternatives.navNativeValue, .alternative)
        XCTAssertEqual(setRouteReason.fallbackToOffline.navNativeValue, .fallbackToOffline)
        XCTAssertEqual(setRouteReason.restoreToOnline.navNativeValue, .restoreToOnline)
        XCTAssertEqual(setRouteReason.fasterRoute.navNativeValue, .fastestRoute)
    }

    func testIsReroute() {
        XCTAssertTrue(setRouteReason.reroute(nil).isReroute)
        XCTAssertTrue(setRouteReason.reroute(.closure).isReroute)
        XCTAssertTrue(setRouteReason.reroute(.deviation).isReroute)
        XCTAssertTrue(setRouteReason.reroute(.routeInvalidated).isReroute)

        XCTAssertFalse(setRouteReason.newRoute.isReroute)
        XCTAssertFalse(setRouteReason.alternatives.isReroute)
        XCTAssertFalse(setRouteReason.fasterRoute.isReroute)
        XCTAssertFalse(setRouteReason.fallbackToOffline.isReroute)
        XCTAssertFalse(setRouteReason.restoreToOnline.isReroute)
    }

    private var setRouteReason: MapboxNavigator.SetRouteReason.Type {
        MapboxNavigator.SetRouteReason.self
    }
}
