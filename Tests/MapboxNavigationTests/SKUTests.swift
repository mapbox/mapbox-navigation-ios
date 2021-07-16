import XCTest
import TestHelper
@testable import MapboxCoreNavigation
import MapboxDirections
import MapboxSpeech
import MapboxNavigation
import MapboxCommon_Private

class SKUTests: TestCase {
    func testDirectionsSKU() {
        billingServiceMock.onGetSKUTokenIfValid = {
            TokenGenerator.getSKUToken(for: .nav2SesTrip)
        }
        let directionsSkuToken = Directions.skuToken
        
        XCTAssertNotNil(directionsSkuToken)
        
        XCTAssertEqual(directionsSkuToken?.skuId, SkuID.nav2SesTrip.rawValue)
    }
    
    func testSpeechSynthesizerSKU() {
        billingServiceMock.onGetSKUTokenIfValid = {
            TokenGenerator.getSKUToken(for: .nav2SesTrip)
        }

        let speechSkuToken = SpeechSynthesizer.skuToken
        
        XCTAssertNotNil(speechSkuToken)
        
        XCTAssertEqual(speechSkuToken?.skuId, SkuID.nav2SesTrip.rawValue)
    }

    func testSKUTokensMatch() {
        let skuToken = TokenGenerator.getSKUToken(for: .nav2SesTrip)
        billingServiceMock.onGetSKUTokenIfValid = { skuToken }

        let viewController = TokenTestViewController()
        let tokenExpectation = XCTestExpectation(description: "All tokens should be fetched")
        viewController.tokenExpectation = tokenExpectation

        viewController.simulatateViewControllerPresented()

        wait(for: [tokenExpectation], timeout: 5)

        XCTAssertNotEqual(viewController.mapViewToken?.skuId, SkuID.navigationUser.rawValue)
        XCTAssertNotEqual(viewController.mapViewToken, viewController.directionsToken)
        XCTAssertNotEqual(viewController.mapViewToken, viewController.speechSynthesizerToken)
        XCTAssertEqual(viewController.speechSynthesizerToken, skuToken)
        XCTAssertEqual(viewController.directionsToken, skuToken)

    }
}
