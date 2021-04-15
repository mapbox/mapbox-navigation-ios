import Foundation
import MapboxNavigationNative

/**
 Proactively fetches tiles which may become necessary if the device loses its Internet connection at some point during passive or active turn-by-turn navigation.
 
 Typically, you initialize an instance of this class and retain it as long as caching is required.
 */
public class PredictiveCacheManager {
    public typealias MapOptions = (tileStore: TileStore, styleSourcePaths: [String])

    private(set) var controllers: [PredictiveCacheController] = []

    /**
     Initializes a predictive cache.
    
     - parameter predictiveCacheOptions: A configuration specifying various caching parameters, such as the radii of current and destination locations.
     - parameter mapOptions: Information about `MapView` tiles such as the location and tilesets to cache. If this argument is set to `nil`, predictive caching is disabled for map tiles.
     */
    public init(predictiveCacheOptions: PredictiveCacheOptions, mapOptions: MapOptions?) {
        Navigator.credentials = predictiveCacheOptions.credentials
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
                                                            dataDomain: .maps,
                                                            concurrency: maxConcurrentRequests,
                                                            maxAverageDownloadBytesPerSecond: 0)
        let predictiveLocationTrackerOptions = PredictiveLocationTrackerOptions(options)
        if let tileStore = tileStore {
            return try? Navigator.shared.navigator.createPredictiveCacheController(for: tileStore,
                                                                                   cacheOptions: cacheOptions,
                                                                                   locationTrackerOptions: predictiveLocationTrackerOptions)
        } else {
            return try? Navigator.shared.navigator.createPredictiveCacheController(for: predictiveLocationTrackerOptions)
        }
    }
}
