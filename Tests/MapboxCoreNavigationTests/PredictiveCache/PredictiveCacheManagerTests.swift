import XCTest
import MapboxCommon
import MapboxNavigationNative
import TestHelper
@testable import MapboxCoreNavigation

final class PredictiveCacheManagerTests: TestCase {
    var navigator: NativeNavigatorSpy!
    var manager: PredictiveCacheManager!

    var tileStore: TileStore!
    var tilesetDescriptor: TilesetDescriptor!
    var cacheMapOptions: PredictiveCacheManager.CacheMapOptions!
    var predictiveCacheOptions: PredictiveCacheOptions!

    override func setUp() {
        super.setUp()

        predictiveCacheOptions = PredictiveCacheOptions()
        navigator = CoreNavigatorSpy.shared.navigatorSpy
        tileStore = CoreNavigatorSpy.shared.tileStore
        tilesetDescriptor = TilesetDescriptorFactory.build(forDataset: "", version: "")
        cacheMapOptions = (tileStore: tileStore, tilesetDescriptor: tilesetDescriptor)

        predictiveCacheOptions.predictiveCacheMapsOptions.maximumConcurrentRequests = 3
        predictiveCacheOptions.predictiveCacheMapsOptions.locationOptions.currentLocationRadius = 30
        predictiveCacheOptions.predictiveCacheMapsOptions.locationOptions.destinationLocationRadius = 300
        predictiveCacheOptions.predictiveCacheMapsOptions.locationOptions.routeBufferRadius = 3000

        predictiveCacheOptions.predictiveCacheNavigationOptions.locationOptions.currentLocationRadius = 40
        predictiveCacheOptions.predictiveCacheNavigationOptions.locationOptions.destinationLocationRadius = 400
        predictiveCacheOptions.predictiveCacheNavigationOptions.locationOptions.routeBufferRadius = 4000
    }

    func testCreateNavigationController() {
        let manager = PredictiveCacheManager(predictiveCacheOptions: predictiveCacheOptions,
                                             cacheMapOptions: nil,
                                             navigatorType: CoreNavigatorSpy.self)
        let expectedOptions = predictiveCacheOptions.predictiveCacheNavigationOptions.locationOptions
        XCTAssertNil(navigator.passedTileStore)
        XCTAssertNil(navigator.passedDescriptorsTrackerOptions)
        XCTAssertEqual(navigator.passedNavigationTrackerOptions?.currentLocationRadius, UInt32(expectedOptions.currentLocationRadius))
        XCTAssertEqual(navigator.passedNavigationTrackerOptions?.destinationLocationRadius, UInt32(expectedOptions.destinationLocationRadius))
        XCTAssertEqual(navigator.passedNavigationTrackerOptions?.routeBufferRadius, UInt32(expectedOptions.routeBufferRadius))

        navigator.passedNavigationTrackerOptions = nil

        manager.updateMapControllers(cacheMapOptions: cacheMapOptions)

        XCTAssertNil(navigator.passedNavigationTrackerOptions, "Does not recreate navigation controller")
    }

    func testCreateNavigationAndMapController() {
        let manager = PredictiveCacheManager(predictiveCacheOptions: predictiveCacheOptions,
                                             cacheMapOptions: cacheMapOptions,
                                             navigatorType: CoreNavigatorSpy.self)

        let expectedMapOptions = predictiveCacheOptions.predictiveCacheMapsOptions.locationOptions
        XCTAssertEqual(navigator.passedTileStore, tileStore)
        XCTAssertEqual(navigator.passedDescriptorsTrackerOptions?.currentLocationRadius, UInt32(expectedMapOptions.currentLocationRadius))
        XCTAssertEqual(navigator.passedDescriptorsTrackerOptions?.destinationLocationRadius, UInt32(expectedMapOptions.destinationLocationRadius))
        XCTAssertEqual(navigator.passedDescriptorsTrackerOptions?.routeBufferRadius, UInt32(expectedMapOptions.routeBufferRadius))
        XCTAssertEqual(navigator.passedDescriptors, [tilesetDescriptor])

        navigator.passedDescriptorsTrackerOptions = nil
        navigator.passedNavigationTrackerOptions = nil

        let newTilesetDescriptor = TilesetDescriptorFactory.build(forDataset: "1", version: "1")
        cacheMapOptions.tilesetDescriptor = newTilesetDescriptor
        manager.updateMapControllers(cacheMapOptions: cacheMapOptions)

        XCTAssertNotNil(navigator.passedDescriptorsTrackerOptions, "Create new map controller")
        XCTAssertEqual(navigator.passedDescriptors, [newTilesetDescriptor])
    }

    func testCreateNavigationAndMapsControllerWhenDidSwitchToTargetVersion() {
        manager = PredictiveCacheManager(predictiveCacheOptions: predictiveCacheOptions,
                                         cacheMapOptions: cacheMapOptions,
                                         navigatorType: CoreNavigatorSpy.self)
        navigator.passedDescriptorsTrackerOptions = nil
        navigator.passedNavigationTrackerOptions = nil

        NotificationCenter.default.post(name: .navigationDidSwitchToTargetVersion, object: nil)

        XCTAssertNotNil(navigator.passedDescriptorsTrackerOptions, "Recreate map controller")
        XCTAssertNotNil(navigator.passedNavigationTrackerOptions, "Recreate navigation controller")
    }

    func testCreateDatasetController() {
        let manager = PredictiveCacheManager(predictiveCacheOptions: predictiveCacheOptions,
                                             cacheMapOptions: (tileStore: tileStore, tilesetDescriptor: nil),
                                             styleSourcePaths: ["first"],
                                             navigatorType: CoreNavigatorSpy.self)

        let expectedMapOptions = predictiveCacheOptions.predictiveCacheMapsOptions.locationOptions
        XCTAssertEqual(navigator.passedDatasetTrackerOptions?.currentLocationRadius, UInt32(expectedMapOptions.currentLocationRadius))
        XCTAssertEqual(navigator.passedDatasetTrackerOptions?.destinationLocationRadius, UInt32(expectedMapOptions.destinationLocationRadius))
        XCTAssertEqual(navigator.passedDatasetTrackerOptions?.routeBufferRadius, UInt32(expectedMapOptions.routeBufferRadius))

        XCTAssertEqual(navigator.passedCacheOptions?.dataset, "first")
        XCTAssertEqual(navigator.passedCacheOptions?.dataDomain, .maps)
        XCTAssertEqual(navigator.passedCacheOptions?.version, "")
        XCTAssertEqual(navigator.passedCacheOptions?.concurrency, predictiveCacheOptions.predictiveCacheMapsOptions.maximumConcurrentRequests)
        XCTAssertEqual(navigator.passedCacheOptions?.maxAverageDownloadBytesPerSecond, 0)

        navigator.passedDatasetTrackerOptions = nil
        manager.updateMapControllers(cacheMapOptions: cacheMapOptions)

        XCTAssertNil(navigator.passedDatasetTrackerOptions)
    }
}
