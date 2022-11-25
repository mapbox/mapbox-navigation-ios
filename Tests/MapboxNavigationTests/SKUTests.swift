import XCTest
import TestHelper
@testable import MapboxCoreNavigation
import MapboxDirections
import MapboxSpeech
import MapboxNavigation
import MapboxCommon_Private

#if DEBUG
class SKUTests: TestCase {
    func testDirectionsSKU() {
        let expected: String = UUID().uuidString
        billingServiceMock.onGetSKUTokenIfValid = { _ in
            expected
        }
        XCTAssertEqual(Directions.shared.skuToken, "")
        BillingHandler.shared.beginBillingSession(for: .freeDrive, uuid: .init())
        let directionsSkuToken = Directions.shared.skuToken
        
        XCTAssertEqual(directionsSkuToken, expected)
    }
    
    func testSpeechSynthesizerSKU() {
        let expected: String = UUID().uuidString

        billingServiceMock.onGetSKUTokenIfValid = { _ in
            expected
        }

        let speechSynthesizer = SpeechSynthesizer(accessToken: billingServiceMock.accessToken)
        XCTAssert(speechSynthesizer.skuToken == nil || speechSynthesizer.skuToken == "")
        BillingHandler.shared.beginBillingSession(for: .freeDrive, uuid: .init())

        let speechSkuToken = speechSynthesizer.skuToken
        
        XCTAssertEqual(speechSkuToken, expected)
    }

    func testSKUTokensMatch() {
        BillingHandler.shared.beginBillingSession(for: .freeDrive, uuid: .init())
        let skuToken = NativeBillingService.shared.getSessionSKUTokenIfValid(for: .nav2SesFDTrip)
        billingServiceMock.onGetSKUTokenIfValid = { _ in skuToken }

        let viewController = TokenTestViewController()
        let tokenExpectation = XCTestExpectation(description: "All tokens should be fetched")
        viewController.tokenExpectation = tokenExpectation

        viewController.simulatateViewControllerPresented()

        wait(for: [tokenExpectation], timeout: 5)

        XCTAssertNotEqual(viewController.mapViewToken, viewController.directionsToken)
        XCTAssertNotEqual(viewController.mapViewToken, viewController.speechSynthesizerToken)
        XCTAssertEqual(viewController.speechSynthesizerToken, skuToken)
        XCTAssertEqual(viewController.directionsToken, skuToken)
    }
}
#endif
