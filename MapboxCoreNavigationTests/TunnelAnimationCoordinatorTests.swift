//
//  TunnelAnimationCoordinatorTests.swift
//  MapboxCoreNavigationTests
//
//  Created by sprinter on 1/26/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import XCTest
import Turf
import CoreLocation
@testable import MapboxCoreNavigation

class TunnelAnimationCoordinatorTests: XCTestCase {
    
    var animationCoordinator = TunnelAnimationCoordinator(Polyline([CLLocationCoordinate2D]()))
    
    override func setUp() {
        super.setUp()
    }
    
    func testIsWithinMinimumSpeed() {
        let acceptedSpeed: CLLocationSpeed = RouteControllerMinimumSpeedForTunnelAnimation + 8
        let unacceptedSpeed: CLLocationSpeed = RouteControllerMinimumSpeedForTunnelAnimation - 5

        XCTAssertTrue(animationCoordinator.isWithinMinimumSpeed(acceptedSpeed))
        XCTAssertFalse(animationCoordinator.isWithinMinimumSpeed(unacceptedSpeed))
    }
    
    func testContainsIdenticalCongestions() {
        let identicalCongestions: [RouteProgress.TimedCongestionLevel] = [(.low, 7.0), (.low, 3.0), (.low, 5.0)]
        let unidenticalCongestions: [RouteProgress.TimedCongestionLevel] = [(.moderate, 7.0), (.low, 3.0), (.low, 5.0)]

        XCTAssertTrue(animationCoordinator.containsIdenticalCongestions(for: identicalCongestions))
        XCTAssertFalse(animationCoordinator.containsIdenticalCongestions(for: unidenticalCongestions))
    }
    
    func testTotalTravelTime() {
        let congestions: [RouteProgress.TimedCongestionLevel] = [(.low, 7.0), (.low, 3.0), (.low, 5.0)]

        XCTAssertEqual(animationCoordinator.totalTravelTime(for: congestions), 15)
        XCTAssertNotEqual(animationCoordinator.totalTravelTime(for: congestions), 20)
    }
    
    func testCongestionsWithinRange() {
        
    }
}
