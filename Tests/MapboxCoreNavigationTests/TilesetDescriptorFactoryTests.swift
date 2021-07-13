import Foundation
import XCTest
import MapboxNavigationNative
import TestHelper
import MapboxDirections
@testable import MapboxCoreNavigation

final class TilesetDescriptorFactoryTests: XCTestCase {
    override func setUp() {
        DirectionsCredentials.injectSharedToken(.mockedAccessToken)
    }

    func testGetLatestDescriptorForNonNavigatorTilesPath() {
        Navigator.tilesURL = FileManager.default.temporaryDirectory
        let tilesetReceived = expectation(description: "Tileset received")
        TilesetDescriptorFactory.getLatest(forCacheLocation: .default,
                                           completionQueue: .global()) { latestTilesetDescriptor in
            tilesetReceived.fulfill()
            XCTAssertNotEqual(latestTilesetDescriptor,
                              TilesetDescriptorFactory.getLatestForCache(Navigator.shared.cacheHandle))
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testLatestDescriptorForNavigatorTilesPath() {
        _ = Navigator.shared // Make sure navigator is created
        Navigator.tilesURL = nil
        let tilesetReceived = expectation(description: "Tileset received")
        TilesetDescriptorFactory.getLatest(forCacheLocation: .default,
                                           completionQueue: .global()) { latestTilesetDescriptor in
            tilesetReceived.fulfill()
            XCTAssertEqual(latestTilesetDescriptor,
                           TilesetDescriptorFactory.getLatestForCache(Navigator.shared.cacheHandle))
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
}
