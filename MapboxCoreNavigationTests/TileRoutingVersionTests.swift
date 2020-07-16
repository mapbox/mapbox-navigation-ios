@testable import MapboxCoreNavigation
import MapboxDirections
import XCTest

class TileRoutingVersionTests: XCTestCase {
    func testCurrentVersionReturnsExpectedValueFirstTime () {
        // Given
        let routeTilesVersion = RouteTilesVersion(with: DirectionsCredentials())
        let expectedCurrentVersion = "2020_07_03-03_00_00"
        
        // When
        let currentVersion = routeTilesVersion.currentVersion
        
        // Then
        XCTAssertEqual(currentVersion, expectedCurrentVersion)
    }
    
    func testCurrentVersionStoresValuePersistently () {
//        // Given
//        let routeTilesVersion = RouteTilesVersion(with: DirectionsCredentials())
//        let expectedCurrentVersion = "2020_07_03-03_00_00"
//
//        // When
//        let currentVersion = routeTilesVersion.currentVersion
//
//        // Then
//        XCTAssertEqual(currentVersion, expectedCurrentVersion)
    }
    
    func testCurrentVersionReadsValuePersistently () {
//        // Given
//        let routeTilesVersion = RouteTilesVersion(with: DirectionsCredentials())
//        let expectedCurrentVersion = "2020_07_03-03_00_00"
//
//        // When
//        let currentVersion = routeTilesVersion.currentVersion
//
//        // Then
//        XCTAssertEqual(currentVersion, expectedCurrentVersion)
    }

    func testGetAvailableVersionsReturnsArrayOfAvailableVersions () {
        // Given
        let expectation = XCTestExpectation(description: "")
        let routeTilesVersion = RouteTilesVersion(with: DirectionsCredentials())
        
        // When
        routeTilesVersion.getAvailableVersions { availableVersions in
            print(availableVersions)
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
}
