import Foundation
import MapboxCommon
import MapboxMaps
import MapboxNavigationNative_Private

/// Proactively fetches tiles which may become necessary if the device loses its Internet connection at some point
/// during passive or active turn-by-turn navigation.
///
/// Typically, you initialize an instance of this class and retain it as long as caching is required. Pass
/// ``MapboxNavigationProvider/predictiveCacheManager`` to your ``NavigationMapView`` instance to use predictive cache.
/// - Note: This object uses global tile store configuration from ``CoreConfig/predictiveCacheConfig``.
public class PredictiveCacheManager {
    private let predictiveCacheOptions: PredictiveCacheConfig
    private let tileStore: TileStore

    private(set) weak var navigator: NavigationNativeNavigator?

    private var mapTilesetDescriptor: TilesetDescriptor?
    private(set) var navigationController: PredictiveCacheController?
    private(set) var mapController: PredictiveCacheController?
    private(set) var searchController: PredictiveCacheController?

    init(
        predictiveCacheOptions: PredictiveCacheConfig,
        tileStore: TileStore,
        styleSourcePaths: [String] = []
    ) {
        self.predictiveCacheOptions = predictiveCacheOptions
        self.tileStore = tileStore
    }

    @MainActor
    public func updateMapControllers(mapView: MapView) {
        let mapsOptions = predictiveCacheOptions.predictiveCacheMapsConfig
        let tilesetDescriptor = mapView.tilesetDescriptor(zoomRange: mapsOptions.zoomRange)
        mapTilesetDescriptor = tilesetDescriptor
        mapController = createMapController(tilesetDescriptor)
    }

    /// Starts predictive caching driven by `navigator`. Calling it again with the same navigator does nothing.
    @MainActor
    func attach(_ navigator: NavigationNativeNavigator) {
        guard self.navigator !== navigator else { return }

        self.navigator = navigator
        navigationController = createNavigationController(for: navigator)
        searchController = createSearchController(for: navigator)
        mapController = createMapController(mapTilesetDescriptor)
    }

    @MainActor
    private func createMapController(_ tilesetDescriptor: TilesetDescriptor?) -> PredictiveCacheController? {
        guard let tilesetDescriptor else { return nil }

        let cacheMapsOptions = predictiveCacheOptions.predictiveCacheMapsConfig
        let predictiveLocationTrackerOptions = PredictiveLocationTrackerOptions(cacheMapsOptions.locationConfig)
        return navigator?.native.createPredictiveCacheController(
            for: tileStore,
            descriptors: [tilesetDescriptor],
            locationTrackerOptions: predictiveLocationTrackerOptions
        )
    }

    @MainActor
    private func createNavigationController(
        for navigator: NavigationNativeNavigator
    ) -> PredictiveCacheController? {
        let locationOptions = predictiveCacheOptions.predictiveCacheNavigationConfig.locationConfig
        let predictiveLocationTrackerOptions = PredictiveLocationTrackerOptions(locationOptions)
        return navigator.native.createPredictiveCacheController(for: predictiveLocationTrackerOptions)
    }

    /// Instantiate a controller for search functionality if the ``PredictiveCacheSearchConfig`` has the necessary
    /// inputs.
    /// Assign `tileStore.setOptionForKey("log-tile-loading", value: true)` and set MapboxCommon log level to info for
    /// debug output
    /// - Returns: A predictive cache controller configured for search functionality.
    @MainActor
    private func createSearchController(for navigator: NavigationNativeNavigator) -> PredictiveCacheController? {
        guard let predictiveCacheSearchConfig = predictiveCacheOptions.predictiveCacheSearchConfig else {
            return nil
        }

        let locationOptions = predictiveCacheSearchConfig.locationConfig
        let predictiveLocationTrackerOptions = PredictiveLocationTrackerOptions(locationOptions)

        return navigator.native.createPredictiveCacheController(
            for: tileStore,
            descriptors: [
                predictiveCacheSearchConfig.searchTilesetDescriptor,
            ],
            locationTrackerOptions: predictiveLocationTrackerOptions
        )
    }
}

extension TilesetDescriptor: @unchecked Sendable {}
extension PredictiveCacheManager: @unchecked Sendable {}
