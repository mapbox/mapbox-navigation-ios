import Foundation
internal import MapboxNavSdk

/// Configuration for the road cameras appearance.
@_spi(ExperimentalMapboxAPI)
public struct RoadCamerasConfig {
    /// The minimum zoom level at which camera icons are displayed.
    public var cameraIconMinZoom: Double

    /// The configuration for displaying road cameras.
    public var displayConfig: RoadCamerasDisplayConfig?

    /// The provider for road camera icons.
    public var iconProvider: RoadCamerasIconProvider?

    public init(
        cameraIconMinZoom: Double = 10,
        displayConfig: RoadCamerasDisplayConfig? = nil,
        iconProvider: RoadCamerasIconProvider? = nil
    ) {
        self.cameraIconMinZoom = cameraIconMinZoom
        self.displayConfig = displayConfig
        self.iconProvider = iconProvider
    }
}

extension RoadCamerasConfig {
    var native: MapboxNavSdk.RoadCamerasConfig {
        MapboxNavSdk.RoadCamerasConfig(
            mapPosition: nil,
            cameraIconMinZoom: cameraIconMinZoom,
            displayConfig: displayConfig?.native,
            displayFilterOnRoute: nil,
            displayFilterInFreeDrive: nil,
            displayFilterInPreview: nil,
            iconProvider: iconProvider.map(RoadCamerasIconProviderAdapter.init)
        )
    }
}
