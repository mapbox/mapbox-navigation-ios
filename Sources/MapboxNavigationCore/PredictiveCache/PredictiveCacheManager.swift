import Foundation
import MapboxCommon
import MapboxMaps
import MapboxNavigationNative

/// Proactively fetches tiles which may become necessary if the device loses its Internet connection at some point
/// during passive or active turn-by-turn navigation.
///
/// Typically, you initialize an instance of this class and retain it as long as caching is required. Pass
/// ``MapboxNavigationProvider/predictiveCacheManager`` to your ``NavigationMapView`` instance to use predictive cache.
/// - Note: This object uses global tile store configuration from ``CoreConfig/predictiveCacheConfig``.
public class PredictiveCacheManager {
    private let predictiveCacheOptions: PredictiveCacheConfig
    private let tileStore: TileStore

    private weak var navigator: NavigationNativeNavigator? {
        didSet {
            _ = mapTilesetDescriptor.map { descriptor in
                Task { @MainActor in
                    self.mapController = createMapController(descriptor)
                }
            }
        }
    }

    private var mapTilesetDescriptor: TilesetDescriptor?
    private var navigationController: PredictiveCacheController?
    private var mapController: PredictiveCacheController?

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

    func updateNavigationController(with navigator: NavigationNativeNavigator?) {
        self.navigator = navigator
        Task { @MainActor in
            navigationController = createNavigationController(for: navigator)
        }
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
        for navigator: NavigationNativeNavigator?
    ) -> PredictiveCacheController? {
        guard let navigator else { return nil }

        let locationOptions = predictiveCacheOptions.predictiveCacheNavigationConfig.locationConfig
        let predictiveLocationTrackerOptions = PredictiveLocationTrackerOptions(locationOptions)
        return navigator.native.createPredictiveCacheController(for: predictiveLocationTrackerOptions)
    }
}

extension TilesetDescriptor: @unchecked Sendable {}
extension PredictiveCacheManager: @unchecked Sendable {}
