import Foundation
import MapboxCommon
import MapboxNavigationNative

/**
 Proactively fetches tiles which may become necessary if the device loses its Internet connection at some point during passive or active turn-by-turn navigation.
 
 Typically, you initialize an instance of this class and retain it as long as caching is required.

 - note: This object uses global tile store configuration from `NavigationSettings.tileStoreConfiguration`.
 */
public class PredictiveCacheManager {
    public typealias CacheMapOptions = (tileStore: TileStore, tilesetDescriptor: TilesetDescriptor?)
    
    @available(*, deprecated, message: "Specify `CacheMapOptions` instead.")
    public typealias MapOptions = (tileStore: TileStore, styleSourcePaths: [String])

    private let predictiveCacheOptions: PredictiveCacheOptions
    private var cacheMapOptions: CacheMapOptions?

    // NOTE: We need to store styleSourcePaths and datasetControllers for backward compatibility.
    private let styleSourcePaths: [String]
    private var datasetControllers: [PredictiveCacheController] = []

    private var navigationController: PredictiveCacheController? = nil
    private var mapController: PredictiveCacheController? = nil

    private let navigatorType: CoreNavigator.Type
    private var navigator: MapboxNavigationNative.Navigator {
        return navigatorType.shared.navigator
    }

    /**
      Initializes a predictive cache.
      Only non-volatile styles will be cached.

      Recommended constructor. This action will initialize tile storage for navigation tiles.

      - parameter predictiveCacheOptions: A configuration specifying various caching parameters, such as the radii of current and destination locations.
      - parameter cacheMapOptions: Information about `MapView` tiles such as the location and tilesets to cache. If this argument is set to `nil`, predictive caching is disabled for map tiles.
      */
    public convenience init(predictiveCacheOptions: PredictiveCacheOptions,
                            cacheMapOptions: CacheMapOptions? = nil) {
        self.init(predictiveCacheOptions: predictiveCacheOptions,
                  cacheMapOptions: cacheMapOptions,
                  navigatorType: Navigator.self)
    }

    /**
     Initializes a predictive cache.

     It is recommended to use `init(predictiveCacheOptions:cacheMapOptions:)` instead to correctly specify tileset for caching of non-volatile styles .
    
     - parameter predictiveCacheOptions: A configuration specifying various caching parameters, such as the radii of current and destination locations.
     - parameter styleSourcePaths: Tilesets names for caching. The SDK ignores this parameter in the latest versions.
     */
    @available(*, deprecated, message: "Use `PredictiveCacheManager.init(predictiveCacheOptions:cacheMapOptions:)` instead.")
    public convenience init(predictiveCacheOptions: PredictiveCacheOptions,
                            styleSourcePaths: [String]) {
        var mapOptions: MapOptions?
        if let tileStore = NavigationSettings.shared.tileStoreConfiguration.mapLocation?.tileStore {
            mapOptions = MapOptions(tileStore, styleSourcePaths)
        }

        self.init(predictiveCacheOptions: predictiveCacheOptions, mapOptions: mapOptions)
    }
    
    /**
     Initializes a predictive cache.

     It is recommended to use `init(predictiveCacheOptions:cacheMapOptions:)` instead to correctly specify tileset for caching of non-volatile styles .
    
     - parameter predictiveCacheOptions: A configuration specifying various caching parameters, such as the radii of current and destination locations.
     - parameter mapOptions: Information about `MapView` tiles such as the location and tilesets to cache. If this argument is set to `nil`, predictive caching is disabled for map tiles.
     */
    @available(*, deprecated, message: "Use `PredictiveCacheManager.init(predictiveCacheOptions:cacheMapOptions:)` instead.")
    public convenience init(predictiveCacheOptions: PredictiveCacheOptions, mapOptions: MapOptions?) {
        var cacheMapOptions: CacheMapOptions? = nil
        if let tileStore = mapOptions?.tileStore {
            cacheMapOptions = (tileStore: tileStore, tilesetDescriptor: nil)
        }

        self.init(predictiveCacheOptions:predictiveCacheOptions,
                  cacheMapOptions: cacheMapOptions,
                  styleSourcePaths: mapOptions?.styleSourcePaths ?? [],
                  navigatorType: Navigator.self)
    }

    init(predictiveCacheOptions: PredictiveCacheOptions,
         cacheMapOptions: CacheMapOptions?,
         styleSourcePaths: [String] = [],
         navigatorType: CoreNavigator.Type) {
        self.predictiveCacheOptions = predictiveCacheOptions
        self.cacheMapOptions = cacheMapOptions
        self.styleSourcePaths = styleSourcePaths
        self.navigatorType = navigatorType

        updateControllers()
        subscribeNotifications()
    }
    
    deinit {
        unsubscribeNotifications()
    }

    /**
     Updates a predictive cache configuration for additional tilesets. Call when new tilesets need to be cached.
     - Parameter cacheMapOptions: Information about `MapView` tiles such as the location and tilesets to cache.
     */
    public func updateMapControllers(cacheMapOptions: CacheMapOptions?) {
        guard let cacheMapOptions = cacheMapOptions else { return }

        self.cacheMapOptions = cacheMapOptions
        self.mapController = createMapController()
    }
    
    private func subscribeNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(restoreToOnline),
                                               name: .navigationDidSwitchToTargetVersion,
                                               object: nil)
    }
    
    private func unsubscribeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .navigationDidSwitchToTargetVersion, object: nil)
    }
    
    @objc func restoreToOnline(_ notification: Notification) {
       updateControllers()
    }

    private func updateControllers() {
        self.navigationController = createNavigationController()
        self.mapController = createMapController()
        self.datasetControllers = createDatasetControllers()
    }

    private func createMapController() -> PredictiveCacheController? {
        guard let cacheMapOptions = cacheMapOptions,
              let tilesetDescriptor = cacheMapOptions.tilesetDescriptor else { return nil }

        let cacheMapsOptions = predictiveCacheOptions.predictiveCacheMapsOptions
        let predictiveLocationTrackerOptions = PredictiveLocationTrackerOptions(cacheMapsOptions.locationOptions)
        return navigator.createPredictiveCacheController(for: cacheMapOptions.tileStore,
                                                         descriptors: [tilesetDescriptor],
                                                         locationTrackerOptions: predictiveLocationTrackerOptions)
    }

    private func createNavigationController() -> PredictiveCacheController {
        let locationOptions = predictiveCacheOptions.predictiveCacheNavigationOptions.locationOptions
        let predictiveLocationTrackerOptions = PredictiveLocationTrackerOptions(locationOptions)
        return navigator.createPredictiveCacheController(for: predictiveLocationTrackerOptions)
    }

    private func createDatasetControllers() -> [PredictiveCacheController] {
        guard let tileStore = cacheMapOptions?.tileStore else { return [] }

        return styleSourcePaths.map { createDatasetController(tileStore: tileStore, dataset: $0) }
    }

    private func createDatasetController(tileStore: TileStore, dataset: String) -> PredictiveCacheController {
        let cacheMapsOptions = predictiveCacheOptions.predictiveCacheMapsOptions
        let predictiveLocationTrackerOptions = PredictiveLocationTrackerOptions(cacheMapsOptions.locationOptions)

        let cacheOptions = PredictiveCacheControllerOptions(version: "",
                                                            dataset: dataset,
                                                            dataDomain: .maps,
                                                            concurrency: cacheMapsOptions.maximumConcurrentRequests,
                                                            maxAverageDownloadBytesPerSecond: 0)
        return navigator.createPredictiveCacheController(for: tileStore,
                                                         cacheOptions: cacheOptions,
                                                         locationTrackerOptions: predictiveLocationTrackerOptions)
    }
}
