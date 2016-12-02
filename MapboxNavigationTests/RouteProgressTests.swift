//
//  RouteProgressTests.swift
//  MapboxNavigation
//
//  Created by Bobby Sudekum on 12/1/16.
//  Copyright © 2016 Mapbox. All rights reserved.
//

import Foundation
import XCTest
import MapboxDirections
@testable import MapboxNavigation

class RouteProgressTests: XCTestCase {
    func testAlertLevels() {
        XCTAssertNotNil(AlertLevel.none)
        XCTAssertNotNil(AlertLevel.depart)
        XCTAssertNotNil(AlertLevel.low)
        XCTAssertNotNil(AlertLevel.medium)
        XCTAssertNotNil(AlertLevel.high)
        XCTAssertNotNil(AlertLevel.arrive)
    }
    
    func testRouteProgress() {
        let routeProgress = RouteProgress(route: route)
        XCTAssertEqual(routeProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.distanceRemaining, 4317.7)
        XCTAssertEqual(routeProgress.distanceTraveled, 0)
        XCTAssertEqual(round(routeProgress.durationRemaining), 790)
    }
    
    func testRouteLegProgress() {
        let routeProgress = RouteProgress(route: route)
        XCTAssertEqual(routeProgress.currentLeg.description, "California Street, Webster Street")
        XCTAssertEqual(routeProgress.currentLegProgress.alertUserLevel, .none)
        XCTAssertEqual(routeProgress.currentLegProgress.distanceTraveled, 0)
        XCTAssertEqual(round(routeProgress.currentLegProgress.durationRemaining), 790)
        XCTAssertEqual(routeProgress.currentLegProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.stepIndex, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.followOnStep?.description, "Turn left onto Webster Street")
        XCTAssertEqual(routeProgress.currentLegProgress.upComingStep?.description, "Turn right onto California Street")
    }
    
    func testRouteStepProgress() {
        let routeProgress = RouteProgress(route: route)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceRemaining, 384.3)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.durationRemaining, 101.7)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation, nil)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.step.description, "Head south on Taylor Street")
    }
    
    func testNextRouteStepProgress() {
        let routeProgress = RouteProgress(route: route)
        routeProgress.currentLegProgress.stepIndex = 1
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceRemaining, 1757.6)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.durationRemaining, 288.9)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation, nil)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.step.description, "Turn right onto California Street")
    }
}
