import _MapboxNavigationTestHelpers
import MapboxCommon
import MapboxMaps
@testable import MapboxNavigationCore
import MapboxNavigationNative
import XCTest

final class PredictiveCacheManagerTests: XCTestCase {
    var mapView: MapView!
    var manager: PredictiveCacheManager!

    var tileStore: TileStore!
    var tilesetDescriptor: TilesetDescriptor!
    var predictiveCacheConfig: PredictiveCacheConfig!
    var navigator: NavigationNativeNavigator!
    var navNavigator: NativeNavigatorSpy!

    let delay: TimeInterval = 0.1

    override func setUp() async throws {
        try? await super.setUp()

        navNavigator = NativeNavigatorSpy()
        navigator = await NavigationNativeNavigator(navigator: navNavigator, locale: .current)
        mapView = await MapView(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
        predictiveCacheConfig = PredictiveCacheConfig()
        let path = NSTemporaryDirectory()
        tileStore = TileStore.__create(forPath: path)
        tilesetDescriptor = TilesetDescriptorFactory.build(forDataset: "", version: "")

        predictiveCacheConfig.predictiveCacheMapsConfig.maximumConcurrentRequests = 3
        predictiveCacheConfig.predictiveCacheMapsConfig.locationConfig.currentLocationRadius = 30
        predictiveCacheConfig.predictiveCacheMapsConfig.locationConfig.destinationLocationRadius = 300
        predictiveCacheConfig.predictiveCacheMapsConfig.locationConfig.routeBufferRadius = 3000

        predictiveCacheConfig.predictiveCacheNavigationConfig.locationConfig.currentLocationRadius = 40
        predictiveCacheConfig.predictiveCacheNavigationConfig.locationConfig.destinationLocationRadius = 400
        predictiveCacheConfig.predictiveCacheNavigationConfig.locationConfig.routeBufferRadius = 4000

        let searchConfig = PredictiveCacheSearchConfig(
            locationConfig: PredictiveCacheLocationConfig(
                currentLocationRadius: 50,
                routeBufferRadius: 500,
                destinationLocationRadius: 5000
            ),
            searchTilesetDescriptor: TilesetDescriptorFactory.build(
                forDataset: "mbx-gen2",
                version: ""
            )
        )
        predictiveCacheConfig.predictiveCacheSearchConfig = searchConfig
    }

    @MainActor
    func testCreateNavigationController() async {
        let manager = PredictiveCacheManager(predictiveCacheOptions: predictiveCacheConfig, tileStore: tileStore)
        manager.updateNavigationController(with: navigator)

        let expectedOptions = predictiveCacheConfig.predictiveCacheNavigationConfig.locationConfig
        XCTAssertNil(navNavigator.passedTileStore)
        XCTAssertNil(navNavigator.passedDescriptorsTrackerOptions)
        XCTAssertEqual(
            navNavigator.passedNavigationTrackerOptions?.currentLocationRadius,
            UInt32(expectedOptions.currentLocationRadius)
        )
        XCTAssertEqual(
            navNavigator.passedNavigationTrackerOptions?.destinationLocationRadius,
            UInt32(expectedOptions.destinationLocationRadius)
        )
        XCTAssertEqual(
            navNavigator.passedNavigationTrackerOptions?.routeBufferRadius,
            UInt32(expectedOptions.routeBufferRadius)
        )

        navNavigator.passedNavigationTrackerOptions = nil

        manager.updateMapControllers(mapView: mapView)

        XCTAssertNil(navNavigator.passedNavigationTrackerOptions, "Does not recreate navigation controller")
    }

    @MainActor
    func testCreateNavigationAndMapController() {
        let manager = PredictiveCacheManager(predictiveCacheOptions: predictiveCacheConfig, tileStore: tileStore)
        manager.updateNavigationController(with: navigator)
        manager.updateMapControllers(mapView: mapView)

        let expectedMapOptions = predictiveCacheConfig.predictiveCacheMapsConfig.locationConfig
        XCTAssertEqual(navNavigator.passedTileStore, tileStore)
        XCTAssertEqual(
            navNavigator.passedDescriptorsTrackerOptions?.currentLocationRadius,
            UInt32(expectedMapOptions.currentLocationRadius)
        )
        XCTAssertEqual(
            navNavigator.passedDescriptorsTrackerOptions?.destinationLocationRadius,
            UInt32(expectedMapOptions.destinationLocationRadius)
        )
        XCTAssertEqual(
            navNavigator.passedDescriptorsTrackerOptions?.routeBufferRadius,
            UInt32(expectedMapOptions.routeBufferRadius)
        )
        let previousDescriptors = navNavigator.passedDescriptors
        XCTAssertEqual(navNavigator.passedDescriptors?.count, 1)

        navNavigator.passedDescriptorsTrackerOptions = nil
        navNavigator.passedNavigationTrackerOptions = nil

        manager.updateMapControllers(mapView: mapView)

        XCTAssertNotNil(navNavigator.passedDescriptorsTrackerOptions, "Create new map controller")
        XCTAssertEqual(navNavigator.passedDescriptors?.count, 1)
        XCTAssertNotEqual(navNavigator.passedDescriptors, previousDescriptors)
    }

    @MainActor
    // TODO: handle navigationDidSwitchToTargetVersion in PredictiveCache
    func disable_testCreateNavigationAndMapsControllerWhenDidSwitchToTargetVersion() {
        let manager = PredictiveCacheManager(predictiveCacheOptions: predictiveCacheConfig, tileStore: tileStore)
        manager.updateNavigationController(with: navigator)
        manager.updateMapControllers(mapView: mapView)

        navNavigator.passedDescriptorsTrackerOptions = nil
        navNavigator.passedNavigationTrackerOptions = nil

        NotificationCenter.default.post(name: .navigationDidSwitchToTargetVersion, object: nil)

        XCTAssertNotNil(navNavigator.passedDescriptorsTrackerOptions, "Recreate map controller")
        XCTAssertNotNil(navNavigator.passedNavigationTrackerOptions, "Recreate navigation controller")
    }

    @MainActor
    // TODO: handle dataset controllers in PredictiveCache
    func disable_testCreateDatasetController() {
        let manager = PredictiveCacheManager(
            predictiveCacheOptions: predictiveCacheConfig, tileStore: tileStore, styleSourcePaths: ["first"]
        )
        manager.updateNavigationController(with: navigator)
        manager.updateMapControllers(mapView: mapView)

        let expectedMapOptions = predictiveCacheConfig.predictiveCacheMapsConfig.locationConfig
        XCTAssertEqual(
            navNavigator.passedDatasetTrackerOptions?.currentLocationRadius,
            UInt32(expectedMapOptions.currentLocationRadius)
        )
        XCTAssertEqual(
            navNavigator.passedDatasetTrackerOptions?.destinationLocationRadius,
            UInt32(expectedMapOptions.destinationLocationRadius)
        )
        XCTAssertEqual(
            navNavigator.passedDatasetTrackerOptions?.routeBufferRadius,
            UInt32(expectedMapOptions.routeBufferRadius)
        )

        XCTAssertEqual(navNavigator.passedCacheOptions?.dataset, "first")
        XCTAssertEqual(navNavigator.passedCacheOptions?.dataDomain, .maps)
        XCTAssertEqual(navNavigator.passedCacheOptions?.version, "")
        XCTAssertEqual(
            navNavigator.passedCacheOptions?.concurrency,
            predictiveCacheConfig.predictiveCacheMapsConfig.maximumConcurrentRequests
        )
        XCTAssertEqual(navNavigator.passedCacheOptions?.maxAverageDownloadBytesPerSecond, 0)

        navNavigator.passedDatasetTrackerOptions = nil
        manager.updateMapControllers(mapView: mapView)

        XCTAssertNil(navNavigator.passedDatasetTrackerOptions)
    }

    @MainActor
    func testCreateSearchController() throws {
        let manager = PredictiveCacheManager(predictiveCacheOptions: predictiveCacheConfig, tileStore: tileStore)
        XCTAssertNotNil(
            predictiveCacheConfig.predictiveCacheSearchConfig?.searchTilesetDescriptor,
            "Requires predictiveCacheConfig to contain a search tileset descriptor"
        )

        manager.updateSearchController(with: navigator)

        let expectedOptions = try XCTUnwrap(predictiveCacheConfig.predictiveCacheSearchConfig?.locationConfig)
        XCTAssertNotNil(navNavigator.passedTileStore)
        XCTAssertNil(navNavigator.passedDatasetTrackerOptions)
        XCTAssertNil(navNavigator.passedNavigationTrackerOptions)

        XCTAssertNotNil(navNavigator.passedDescriptorsTrackerOptions)
        XCTAssertEqual(
            navNavigator.passedDescriptorsTrackerOptions?.currentLocationRadius,
            UInt32(expectedOptions.currentLocationRadius)
        )
        XCTAssertEqual(
            navNavigator.passedDescriptorsTrackerOptions?.destinationLocationRadius,
            UInt32(expectedOptions.destinationLocationRadius)
        )
        XCTAssertEqual(
            navNavigator.passedDescriptorsTrackerOptions?.routeBufferRadius,
            UInt32(expectedOptions.routeBufferRadius)
        )

        navNavigator.passedDatasetTrackerOptions = nil

        manager.updateMapControllers(mapView: mapView)

        XCTAssertNil(navNavigator.passedNavigationTrackerOptions, "Does not recreate navigation controller")
    }
}
