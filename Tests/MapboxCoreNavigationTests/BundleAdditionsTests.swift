import XCTest
import TestHelper
@testable import MapboxCoreNavigation

class BundleAdditionsTests: TestCase {
    
    func testMapboxCoreNavigationInvalidBundle() {
        #if SWIFT_PACKAGE
        guard let `class` = NSClassFromString("MapboxCoreNavigationTests.BundleAdditionsTests") else {
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
        guard let `class` = NSClassFromString("MapboxCoreNavigation.RouteController") else {
            XCTFail("Class should be present.")
            return
        }
        
        let bundle = Bundle.bundle(for: "MapboxNavigation_MapboxCoreNavigation", class: `class`)
        XCTAssertNotNil(bundle, "Bundle should be valid.")
        #else
        NSLog("\(#function) was skipped, as it's intended to be executed only for SPM based tests.")
        #endif
    }
    
    func testMapboxCoreNavigationBundle() {
        #if SWIFT_PACKAGE
        let bundle = Bundle.mapboxCoreNavigation
        XCTAssertNotNil(bundle, "Bundle should be valid.")
        
        let mapboxCoreNavigationInfoDictionary = Bundle.mapboxCoreNavigationInfoDictionary
        XCTAssertNotNil(mapboxCoreNavigationInfoDictionary, "Info dictionary should be valid.")
        
        let validKey = Bundle.string(forMapboxCoreNavigationInfoDictionaryKey: "CFBundleShortVersionString")
        XCTAssertNotNil(validKey, "Key should be valid.")
        
        let invalidKey = Bundle.string(forMapboxCoreNavigationInfoDictionaryKey: "invalidKey")
        XCTAssertNil(invalidKey, "Key should not be valid.")
        #else
        NSLog("\(#function) was skipped, as it's intended to be executed only for SPM based tests.")
        #endif
    }
    
    func testMapboxNavigationBundle() {
        #if SWIFT_PACKAGE
        let mapboxNavigationInfoDictionary = Bundle.mapboxNavigationInfoDictionary
        XCTAssertNotNil(mapboxNavigationInfoDictionary, "Info dictionary should be valid.")
        
        let validKey = Bundle.string(forMapboxNavigationInfoDictionaryKey: "CFBundleShortVersionString")
        XCTAssertNotNil(validKey, "Key should be valid.")
        
        let invalidKey = Bundle.string(forMapboxCoreNavigationInfoDictionaryKey: "invalidKey")
        XCTAssertNil(invalidKey, "Key should not be valid.")
        #else
        NSLog("\(#function) was skipped, as it's intended to be executed only for SPM based tests.")
        #endif
    }
}
