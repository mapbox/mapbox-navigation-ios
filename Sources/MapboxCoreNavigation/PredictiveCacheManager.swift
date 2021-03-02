import Foundation
import MapboxNavigationNative

/**
 `PredictiveCacheManager` is responsible for creating and retaining `Predictive Caching` related components.
 
 Typical usage suggests initializing an instance of `PredictiveCacheManager` and retaining it as long as caching is required.
 */
public class PredictiveCacheManager {
    public typealias MapOptions = (tileStore: TileStore, styleSourcePaths: [String])
    
    private(set) var controllers: [PredictiveCacheController] = []
    
    /**
     Default initializer
     
     - parameter predictiveCacheOptions: `PredictiveCacheOptions` which configures various caching parameters like radiuses of current and destination locations.
     - parameter mapOptions: A `MapOptions` which contains info about `MapView` tiles like its location and tilesets to be cached. If set to `nil` - predictive caching won't be enbled for map tiles.
     */
    public init(predictiveCacheOptions: PredictiveCacheOptions, mapOptions: MapOptions?) {
        self.controllers.append(initNavigatorController(options: predictiveCacheOptions))
        if let mapOptions = mapOptions {
            self.controllers.append(contentsOf: initMapControllers(options: predictiveCacheOptions, mapOptions: mapOptions))
        }
    }
    
    private func initMapControllers(options: PredictiveCacheOptions,
                                    mapOptions: MapOptions) -> [PredictiveCacheController] {
        return mapOptions.styleSourcePaths.compactMap {
            createPredictiveCacheController(options: options,
                                            tileStore: mapOptions.tileStore,
                                            dataset: $0)
        }
    }
    
    private func initNavigatorController(options: PredictiveCacheOptions) -> PredictiveCacheController {
        return createPredictiveCacheController(options: options)!
    }
    
    private func createPredictiveCacheController(options: PredictiveCacheOptions,
                                                 tileStore: TileStore? = nil,
                                                 version: String = "",
                                                 dataset: String = "mapbox",
                                                 maxConcurrentRequests: UInt32 = 2) -> PredictiveCacheController? {
        let cacheOptions = PredictiveCacheControllerOptions(version: version,
                                                            dataset: dataset,
                                                            concurrency: maxConcurrentRequests)
        let predictiveLocationTrackerOptions = PredictiveLocationTrackerOptions(options)
        if let tileStore = tileStore {
            return try! Navigator.shared.navigator.createPredictiveCacheController(for: tileStore,
                                                                                   cacheOptions: cacheOptions,
                                                                                   locationTrackerOptions: predictiveLocationTrackerOptions)
        } else {
            return try! Navigator.shared.navigator.createPredictiveCacheController(for: predictiveLocationTrackerOptions)
        }
    }
}
