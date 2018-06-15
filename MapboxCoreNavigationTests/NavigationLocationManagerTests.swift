//
//  NavigationLocationManagerTests.swift
//  MapboxCoreNavigationTests
//
//  Created by Bobby Sudekum on 6/15/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import XCTest
import MapboxCoreNavigation

class NavigationLocationManagerTests: XCTestCase {
    
    func testNavigationLocationManagerDefaultAccuracy() {
        let locationManager = NavigationLocationManager()
        XCTAssertEqual(locationManager.desiredAccuracy, kCLLocationAccuracyBest)
    }
}
