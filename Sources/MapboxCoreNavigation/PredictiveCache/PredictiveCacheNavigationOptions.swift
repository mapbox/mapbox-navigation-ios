import Foundation

/**
 Specifies predictive cache Navigation related options.
 */
public struct PredictiveCacheNavigationOptions {
    
    /**
     Location configuration for guidance predictive caching
     */
    public var locationOptions: PredictiveCacheLocationOptions = .init()
    
    public init() {
        // No-op
    }
}
