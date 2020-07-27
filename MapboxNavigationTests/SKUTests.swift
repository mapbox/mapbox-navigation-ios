import XCTest
import Mapbox
import MapboxCoreNavigation
import MapboxDirections
import MapboxSpeech
import MapboxNavigation

class SKUTests: XCTestCase {
    
    // Billing per monthly active user (MAU), the default, corresponds to `MBXAccountsSKUID.navigationUser`.
    
    func testDirectionsSKU() {
        let directionsSkuToken = Directions.skuToken
        
        XCTAssertNotNil(directionsSkuToken)
        
        XCTAssertEqual(directionsSkuToken?.skuId, SkuID.navigationUser.rawValue)
    }
    
    func testSpeechSynthesizerSKU() {
        let speechSkuToken = SpeechSynthesizer.skuToken
        
        XCTAssertNotNil(speechSkuToken)
        
        XCTAssertEqual(speechSkuToken?.skuId, SkuID.navigationUser.rawValue)
    }
    
    func testSKUTokensMatch() {
        let viewController = TokenTestViewController()
        let tokenExpectation = XCTestExpectation(description: "All tokens should be fetched")
        viewController.tokenExpectation = tokenExpectation
        
        let rootViewController = UIApplication.shared.delegate!.window!!.rootViewController!
        rootViewController.present(viewController, animated: false)
        
        wait(for: [tokenExpectation], timeout: 5)
        
        XCTAssertEqual(viewController.mapViewToken!.skuId, SkuID.navigationUser.rawValue)
        XCTAssertEqual(viewController.mapViewToken, viewController.directionsToken)
        XCTAssertEqual(viewController.mapViewToken, viewController.speechSynthesizerToken)
        
        let dismissExpectation = XCTestExpectation(description: "VC should be dismissed")
        viewController.dismiss(animated: false) {
            dismissExpectation.fulfill()
        }
        
        wait(for: [dismissExpectation], timeout: 3)
    }
}
