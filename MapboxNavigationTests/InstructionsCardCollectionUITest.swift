//
//  InstructionsCardCollectionUITest.swift
//  MapboxNavigationTests
//
//  Created by Vincent Sam on 5/1/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import XCTest

class InstructionsCardCollectionUITest: XCTestCase {
    
    var app: XCUIApplication!

    /**
     /// TODO:
     Create UI tests for these case scenarios
        1. Scroll through the cards - Preview mode (Portrait mode) (UI Test)
            a. Forward
            b. Backward
     */
    
    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app = XCUIApplication(bundleIdentifier: "com.mapbox.Example")
    }

    func testSwipeFirstInstructionsCard() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        // app.launch()
    }
}
