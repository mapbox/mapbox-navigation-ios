import XCTest
@testable import TestHelper
@testable import MapboxCoreNavigation


class NavigationEventsManagerTests: XCTestCase {

    func testMobileEventsManagerIsInitializedImmediately() {
        let mobileEventsManagerSpy = MMEEventsManagerSpy()
        let _ = NavigationEventsManager(dataSource: nil, accessToken: "example token", mobileEventsManager: mobileEventsManagerSpy)

        XCTAssertEqual(mobileEventsManagerSpy.accessToken, "example token")
    }
}
