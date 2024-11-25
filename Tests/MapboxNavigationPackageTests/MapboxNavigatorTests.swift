//
//  MapboxNavigatorTests.swift
//
//
//  Created by Maksim Chizhavko on 11/23/24.
//

import CoreLocation
import Foundation
@testable import MapboxNavigationCore
@testable import TestHelper
import XCTest

class MapboxNavigatorTests: TestCase {
    @MainActor
    func testSetStateToIdle() async {
        let session = navigationProvider.mapboxNavigation.tripSession() as! MapboxNavigator
        try? await session.startFreeDriveAsync()
        await session.setToIdleAsync()
        let state = session.currentSession.state
        XCTAssertEqual(state, .idle)
    }

    @MainActor
    func testSetStateToFreeDrive() async {
        let session = navigationProvider.mapboxNavigation.tripSession() as! MapboxNavigator
        await session.setToIdleAsync()
        try? await session.startFreeDriveAsync()
        let state = session.currentSession.state
        XCTAssertEqual(state, .freeDrive(.active))
    }
}
