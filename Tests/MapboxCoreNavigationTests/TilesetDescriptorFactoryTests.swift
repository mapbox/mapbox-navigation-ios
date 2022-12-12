import Foundation
import XCTest
import MapboxNavigationNative
import TestHelper
import MapboxDirections
@testable import MapboxCoreNavigation

final class TilesetDescriptorFactoryTests: TestCase {
    
    func testLatestDescriptorsAreFromGlobalNavigatorCacheHandle() {
        let settingsValues = NavigationSettings.Values(directions: .mocked,
                                                       tileStoreConfiguration: .custom(FileManager.default.temporaryDirectory),
                                                       routingProviderSource: .offline,
                                                       alternativeRouteDetectionStrategy: .init())
        NavigationSettings.shared.initialize(with: settingsValues)
        _ = Navigator.shared

        let tilesetReceived = expectation(description: "Tileset received")
        TilesetDescriptorFactory.getLatest(completionQueue: .global(), datasetProfileIdentifier: MapboxCoreNavigation.Navigator.datasetProfileIdentifier) { latestTilesetDescriptor in
            XCTAssertEqual(latestTilesetDescriptor,
                           TilesetDescriptorFactory.getLatestForCache(Navigator.shared.cacheHandle))
            tilesetReceived.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
}
