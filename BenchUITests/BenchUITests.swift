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
        
        // TODO: Grant access to location permissions
        
        let endNavigation = app.staticTexts["You have arrived"]
        let exists = NSPredicate(format: "endNavigation == 1")
        _ = self.expectation(for: exists, evaluatedWith: endNavigation, handler: nil)
        self.waitForExpectations(timeout: 60*2, handler: nil)
        
        app.buttons.staticTexts["End Navigation"].tap()
        
        print("done")
    }
}
