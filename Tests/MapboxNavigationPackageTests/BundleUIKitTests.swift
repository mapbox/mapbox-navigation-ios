@testable import MapboxNavigationUIKit
import XCTest

final class BundleUIKitTests: XCTestCase {
    func testMapboxNavigationUIKitBundle() {
#if SWIFT_PACKAGE
        let bundle = Bundle.mapboxNavigation
        XCTAssertNotNil(bundle, "Bundle should be valid.")
#else
        NSLog("\(#function) was skipped, as it's intended to be executed only for SPM based tests.")
#endif
    }
}
