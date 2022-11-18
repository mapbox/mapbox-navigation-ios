import Foundation

/**
 Specifies predictive cache Maps related options.
 */
public struct PredictiveCacheMapsOptions {
    
    /**
     Location configuration for visual map predictive caching
     */
    public var locationOptions: PredictiveCacheLocationOptions = .init()
    
    /**
     Maxiumum amount of concurrent requests, which will be used for caching.

     Defaults to 2 concurrent requests.
     */
    public var maximumConcurrentRequests: UInt32 = 2

    /**
     Closed range zoom level for the tile package..
     See `TilesetDescriptorOptionsForTilesets.minZoom` and `TilesetDescriptorOptionsForTilesets.maxZoom`.

     Defaults to 0..16.
     */
    public var zoomRange: ClosedRange<UInt8> = 0...16
    
    public init() {
        // No-op
    }
}
