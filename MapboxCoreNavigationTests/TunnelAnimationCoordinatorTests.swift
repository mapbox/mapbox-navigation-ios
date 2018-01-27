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
        
    }
    
    func testContainsIdenticalCongestions() {
        let identicalCongestions: [RouteProgress.TimedCongestionLevel] = [(.low, 7.0), (.low, 3.0), (.low, 5.0)]
        XCTAssertTrue(animationCoordinator.containsIdenticalCongestions(for: identicalCongestions))
        
        let unidenticalCongestions: [RouteProgress.TimedCongestionLevel] = [(.moderate, 7.0), (.low, 3.0), (.low, 5.0)]
        XCTAssertFalse(animationCoordinator.containsIdenticalCongestions(for: unidenticalCongestions))
    }
    
    func testTotalTravelTime() {
        let congestions: [RouteProgress.TimedCongestionLevel] = [(.low, 7.0), (.low, 3.0), (.low, 5.0)]
        XCTAssertEqual(animationCoordinator.totalTravelTime(for: congestions), 15)
    }
    
    func testCongestionsWithinRange() {
        
    }
}
