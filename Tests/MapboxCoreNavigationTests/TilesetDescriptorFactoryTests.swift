import Foundation
import XCTest
import MapboxNavigationNative
import TestHelper
import MapboxDirections
@testable import MapboxCoreNavigation

final class TilesetDescriptorFactoryTests: TestCase {
    
    override func tearDown() {
        NavigationSettings.shared.initialize(directions: .shared, tileStoreConfiguration: .default)
        super.tearDown()
    }
    
    func testLatestDescriptorsAreFromGlobalNavigatorCacheHandle() {
        NavigationSettings.shared.initialize(directions: .mocked,
                                             tileStoreConfiguration: .custom(FileManager.default.temporaryDirectory))
        MapboxCoreNavigation.Navigator._recreateNavigator()

        let tilesetReceived = expectation(description: "Tileset received")
        TilesetDescriptorFactory.getLatest(completionQueue: .global()) { latestTilesetDescriptor in
            tilesetReceived.fulfill()
            XCTAssertEqual(latestTilesetDescriptor,
                           TilesetDescriptorFactory.getLatestForCache(Navigator.shared.cacheHandle))
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
}
