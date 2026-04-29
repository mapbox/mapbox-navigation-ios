@testable import MapboxNavigationCore
import XCTest

final class BundleTests: XCTestCase {
    func testMapboxNavigationCoreInvalidBundle() {
#if SWIFT_PACKAGE
        guard let `class` = NSClassFromString("MapboxNavigationCoreTests.BundleTests") else {
            XCTFail("Class should be present.")
            return
        }

        let bundle = Bundle.bundle(for: "InvalidBundleName", class: `class`)
        XCTAssertNil(bundle, "Bundle should not be valid.")
#else
        NSLog("\(#function) was skipped, as it's intended to be executed only for SPM based tests.")
#endif
    }

    func testMapboxCoreNavigationValidBundle() {
#if SWIFT_PACKAGE
        guard let `class` = NSClassFromString("MapboxNavigationCore.MapboxNavigator") else {
            XCTFail("Class should be present.")
            return
        }

        let bundle = Bundle.bundle(for: "MapboxNavigation_MapboxNavigationCore", class: `class`)
        XCTAssertNotNil(bundle, "Bundle should be valid.")
#else
        NSLog("\(#function) was skipped, as it's intended to be executed only for SPM based tests.")
#endif
    }

    func testMapboxCoreNavigationBundle() {
#if SWIFT_PACKAGE
        let bundle = Bundle.mapboxNavigationUXCore
        XCTAssertNotNil(bundle, "Bundle should be valid.")
#else
        NSLog("\(#function) was skipped, as it's intended to be executed only for SPM based tests.")
#endif
    }
}
