import Foundation

/// Specifies predictive cache Maps related config.
public struct PredictiveCacheMapsConfig: Equatable, Sendable {
    /// Location configuration for visual map predictive caching.
    public var locationConfig: PredictiveCacheLocationConfig = .init()

    /// Maxiumum amount of concurrent requests, which will be used for caching.
    /// Defaults to 2 concurrent requests.
    public var maximumConcurrentRequests: UInt32 = 2

    /// Closed range zoom level for the tile package.
    /// See `TilesetDescriptorOptionsForTilesets.minZoom` and `TilesetDescriptorOptionsForTilesets.maxZoom`.
    /// Defaults to 0..16.
    public var zoomRange: ClosedRange<UInt8> = 0...16

    /// Creates a new ``PredictiveCacheMapsConfig`` instance.
    /// - Parameters:
    ///   - locationConfig: Location configuration for visual map predictive caching.
    ///   - maximumConcurrentRequests: Maxiumum amount of concurrent requests, which will be used for caching.
    ///   - zoomRange: Closed range zoom level for the tile package.
    public init(
        locationConfig: PredictiveCacheLocationConfig = .init(),
        maximumConcurrentRequests: UInt32 = 2,
        zoomRange: ClosedRange<UInt8> = 0...16
    ) {
        self.locationConfig = locationConfig
        self.maximumConcurrentRequests = maximumConcurrentRequests
        self.zoomRange = zoomRange
    }
}
