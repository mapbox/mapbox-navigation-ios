import XCTest
import MapboxNavigation
import MapboxCoreNavigation


class BenchUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
        XCUIApplication().launch()
    }

    func testControlRoute1() {
        let app = XCUIApplication()

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            startMeasuring()
            app.tables.staticTexts["DCA to Arboretum"].tap()

            let endNavigation = app.staticTexts["End Navigation"]
            let exists = NSPredicate(format: "endNavigation == 1")
            expectation(for: exists, evaluatedWith: endNavigation, handler: nil)
            waitForExpectations(timeout: 20*60, handler: nil)

            stopMeasuring()
        }
    }
    
    func testControlRoute2() {
        let app = XCUIApplication()
        
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            startMeasuring()
            
            app.tables.staticTexts["Pipe Fitters Union to Four Seasons Boston"].tap()
            
            let endNavigation = app.staticTexts["End Navigation"]
            let exists = NSPredicate(format: "endNavigation == 1")
            _ = self.expectation(for: exists, evaluatedWith: endNavigation, handler: nil)
            self.waitForExpectations(timeout: 11*60, handler: nil)
            
            stopMeasuring()
        }
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
        
        app.tap() // Triggers the locationHandler
        
        waitForElementToAppear(app.staticTexts["You have arrived"], timeout: 60*2)
        
        removeUIInterruptionMonitor(locationHandler)
    }
    
    func waitForElementToAppear(_ element: XCUIElement, timeout: TimeInterval) {
        let existsPredicate = NSPredicate(format: "exists == true")
        expectation(for: existsPredicate, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: timeout, handler: nil)
    }
}
