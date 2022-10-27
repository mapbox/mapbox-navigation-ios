import Foundation
import MapboxCommon
import MapboxNavigationNative

/**
 Proactively fetches tiles which may become necessary if the device loses its Internet connection at some point during passive or active turn-by-turn navigation.
 
 Typically, you initialize an instance of this class and retain it as long as caching is required.

 - note: This object uses global tile store configuration from `NavigationSettings.tileStoreConfiguration`.
 */
public class PredictiveCacheManager {
    public typealias MapOptions = (tileStore: TileStore, styleSourcePaths: [String])
    
    private var controllers: [PredictiveCacheController] = []
    private var predictiveCacheOptions: PredictiveCacheOptions
    private var mapOptions: MapOptions?
    
    /**
     Initializes a predictive cache.
     
     Recommended constructor. This action will initialize tile storage for navigation tiles.
    
     - parameter predictiveCacheOptions: A configuration specifying various caching parameters, such as the radii of current and destination locations.
     - parameter styleSourcePaths: Tilesets names for caching.
     */
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
     
     This action will initialize tile storage for navigation tiles.
     It is recommended to use `init(predictiveCacheOptions:styleSourcePaths:)` instead to control navigator storage location.
    
     - parameter predictiveCacheOptions: A configuration specifying various caching parameters, such as the radii of current and destination locations.
     - parameter mapOptions: Information about `MapView` tiles such as the location and tilesets to cache. If this argument is set to `nil`, predictive caching is disabled for map tiles.
     - seealso: `PredictiveCacheManager.init(predictiveCacheOptions:styleSourcePaths:)`
     */
    public init(predictiveCacheOptions: PredictiveCacheOptions, mapOptions: MapOptions?) {
        self.predictiveCacheOptions = predictiveCacheOptions
        self.mapOptions = mapOptions
        
        self.controllers = createControllers()
        
        subscribeNotifications()
    }
    
    deinit {
        unsubscribeNotifications()
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
        self.controllers = createControllers()
    }
    
    private func createControllers() -> [PredictiveCacheController] {
        var controllers = [createPredictiveCacheController(options: predictiveCacheOptions)!]
        
        if let mapOptions = mapOptions {
            controllers.append(contentsOf: mapOptions.styleSourcePaths.compactMap {
                createPredictiveCacheController(options: predictiveCacheOptions,
                                                tileStore: mapOptions.tileStore,
                                                dataset: $0)
            })
        }
        return controllers
    }
    
    private func createPredictiveCacheController(options: PredictiveCacheOptions,
                                                 tileStore: TileStore? = nil,
                                                 version: String = "",
                                                 dataset: String = "mapbox",
                                                 maxConcurrentRequests: UInt32 = 2) -> PredictiveCacheController? {
        let predictiveLocationTrackerOptions = PredictiveLocationTrackerOptions(options)
        let navigator = Navigator.shared
        if let tileStore = tileStore {
            let cacheOptions = PredictiveCacheControllerOptions(version: version,
                                                                dataset: dataset,
                                                                dataDomain: .maps,
                                                                concurrency: maxConcurrentRequests,
                                                                maxAverageDownloadBytesPerSecond: 0)
            return navigator.navigator.createPredictiveCacheController(for: tileStore,
                                                                cacheOptions: cacheOptions,
                                                                locationTrackerOptions: predictiveLocationTrackerOptions)
        } else {
            return navigator.navigator.createPredictiveCacheController(for: predictiveLocationTrackerOptions)
        }
    }
}
