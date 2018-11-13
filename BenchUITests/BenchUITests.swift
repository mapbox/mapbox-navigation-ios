import XCTest
import MapboxNavigation
import MapboxCoreNavigation


class BenchUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
        XCUIApplication().launch()
    }
    
    func testTemporaryRoute() {
        let app = XCUIApplication()
        
        app.tables.staticTexts["Temporary Control Route"].tap()
        
        let locationHandler = addUIInterruptionMonitor(withDescription: "Location Permissions") { (alert) -> Bool in
            if alert.buttons["Allow"].exists {
                alert.buttons.element(boundBy: 1).tap()
                return true
            }
            
            return false
        }
        
        app.tap() // Triggers UIInterruptionMonitor
        
        let endNavigationButton = app.buttons["End Navigation"]
        waitForElementToAppear(endNavigationButton, timeout: 60*2)
        
        endNavigationButton.tap()
        
        removeUIInterruptionMonitor(locationHandler)
    }
    
    func waitForElementToAppear(_ element: XCUIElement, timeout: TimeInterval) {
        let existsPredicate = NSPredicate(format: "exists == true")
        expectation(for: existsPredicate, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: timeout, handler: nil)
    }
}
