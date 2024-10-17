import Foundation
import MapboxCommon

/// Predictive cache search related options.
public struct PredictiveCacheSearchConfig: Equatable, Sendable {
    /// Location configuration for visual map predictive caching.
    public var locationConfig: PredictiveCacheLocationConfig = .init()

    /// TilesetDescriptor to use specifically for Search domain predictive cache.
    /// Must be configured for Search tileset usage.
    /// Required when used with `PredictiveCacheManager`.
    public var searchTilesetDescriptor: TilesetDescriptor

    /// Create a new ``PredictiveCacheSearchConfig`` instance.
    /// - Parameters:
    ///   - locationConfig: Location configuration for predictive caching.
    ///   - searchTilesetDescriptor: Required TilesetDescriptor for search domain predictive caching.
    public init(
        locationConfig: PredictiveCacheLocationConfig = .init(),
        searchTilesetDescriptor: TilesetDescriptor
    ) {
        self.locationConfig = locationConfig
        self.searchTilesetDescriptor = searchTilesetDescriptor
    }
}
