import Foundation
import MapboxCommon
import MapboxNavigationNative

/**
 Proactively fetches tiles which may become necessary if the device loses its Internet connection at some point during passive or active turn-by-turn navigation.
 
 Typically, you initialize an instance of this class and retain it as long as caching is required.

 - note: This object uses global tile store configuration from `NavigationSettings.tileStoreConfiguration`.
 */
public class PredictiveCacheManager {
    public typealias CacheMapOptions = (tileStore: TileStore, tilesetDescriptor: TilesetDescriptor)
    
    @available(*, deprecated, message: "Specify `CacheMapOptions` instead.")
    public typealias MapOptions = (tileStore: TileStore, styleSourcePaths: [String])

    private let navigatorProvider: NativeNavigatorProvider.Type
    private let predictiveCacheOptions: PredictiveCacheOptions
    private var cacheMapOptions: CacheMapOptions?

    private var navigationController: PredictiveCacheController? = nil
    private var mapController: PredictiveCacheController? = nil

    private var navigator: MapboxNavigationNative.Navigator {
        return navigatorProvider.navigator
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
                  navigatorProvider: Navigator.self)
    }

    /**
     Initializes a predictive cache. Enables only navigation cache. The only way to map enable caching is to pass a non-nil `cacheMapOptions`.

     It is recommended to use `init(predictiveCacheOptions:cacheMapOptions:)` instead to correctly specify tileset for caching of non-volatile styles .
    
     - parameter predictiveCacheOptions: A configuration specifying various caching parameters, such as the radii of current and destination locations.
     - parameter styleSourcePaths: Tilesets names for caching. The SDK ignores this parameter in the latest versions.
     */
    @available(*, deprecated, message: "Use `PredictiveCacheManager.init(predictiveCacheOptions:cacheMapOptions:)` instead.")
    public convenience init(predictiveCacheOptions: PredictiveCacheOptions,
                            styleSourcePaths: [String]) {
        self.init(predictiveCacheOptions: predictiveCacheOptions, cacheMapOptions: nil)
    }
    
    /**
     Initializes a predictive cache. Enables only navigation cache. The only way to enable map caching is to pass a non-nil `cacheMapOptions`.

     It is recommended to use `init(predictiveCacheOptions:cacheMapOptions:)` instead to correctly specify tileset for caching of non-volatile styles .
    
     - parameter predictiveCacheOptions: A configuration specifying various caching parameters, such as the radii of current and destination locations.
     - parameter mapOptions: Information about `MapView` tiles such as the location and tilesets to cache. If this argument is set to `nil`, predictive caching is disabled for map tiles.
     */
    @available(*, deprecated, message: "Use `PredictiveCacheManager.init(predictiveCacheOptions:cacheMapOptions:)` instead.")
    public convenience init(predictiveCacheOptions: PredictiveCacheOptions, mapOptions: MapOptions?) {
        self.init(predictiveCacheOptions:predictiveCacheOptions, cacheMapOptions: nil)
    }

    init(predictiveCacheOptions: PredictiveCacheOptions,
         cacheMapOptions: CacheMapOptions?,
         navigatorProvider: NativeNavigatorProvider.Type) {
        self.predictiveCacheOptions = predictiveCacheOptions
        self.cacheMapOptions = cacheMapOptions
        self.navigatorProvider = navigatorProvider

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
        self.navigationController = createNavigationCacheController()
        self.mapController = createMapController()
    }

    private func createMapController() -> PredictiveCacheController? {
        guard let cacheMapOptions = cacheMapOptions else { return nil }

        let cacheMapsOptions = predictiveCacheOptions.predictiveCacheMapsOptions
        let predictiveLocationTrackerOptions = PredictiveLocationTrackerOptions(cacheMapsOptions.locationOptions)
        return navigator.createPredictiveCacheController(for: cacheMapOptions.tileStore,
                                                         descriptors: [cacheMapOptions.tilesetDescriptor],
                                                         locationTrackerOptions: predictiveLocationTrackerOptions)
    }

    private func createNavigationCacheController() -> PredictiveCacheController {
        let locationOptions = predictiveCacheOptions.predictiveCacheNavigationOptions.locationOptions
        let predictiveLocationTrackerOptions = PredictiveLocationTrackerOptions(locationOptions)
        return navigator.createPredictiveCacheController(for: predictiveLocationTrackerOptions)
    }
}
