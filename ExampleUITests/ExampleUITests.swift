import XCTest

class ExampleUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func testSKUTokensMatch() {
        let app = XCUIApplication()
        app.launchArguments = ["enable-ui-testing"]
        app.launch()

        let mapViewLabel = app.staticTexts.element(matching:.any, identifier: "MapView SKU")
        let directionsLabel = app.staticTexts.element(matching:.any, identifier: "Directions SKU")
        let speechSynthesizerLabel = app.staticTexts.element(matching:.any, identifier: "SpeechSynthesizer SKU")
                
        XCTAssertTrue(speechSynthesizerLabel.waitForExistence(timeout: 5))
        XCTAssertTrue(directionsLabel.waitForExistence(timeout: 5))
        XCTAssertTrue(mapViewLabel.waitForExistence(timeout: 5))
        
        let mapViewToken = mapViewLabel.label
        let directionsToken = directionsLabel.label
        let speechSynthesizerToken = speechSynthesizerLabel.label
        
        XCTAssertEqual(mapViewToken.skuId, SkuID.navigationUser.rawValue)
        XCTAssertEqual(mapViewToken, directionsToken)
        XCTAssertEqual(mapViewToken, speechSynthesizerToken)
    }
}
