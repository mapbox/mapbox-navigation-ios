import Foundation

/// Specifies predictive cache Navigation related config.
public struct PredictiveCacheNavigationConfig: Equatable, Sendable {
    /// Location configuration for predictive caching.
    public var locationConfig: PredictiveCacheLocationConfig = .init()

    /// Creates a new ``PredictiveCacheNavigationConfig`` instance.
    /// - Parameter locationConfig: Location configuration for predictive caching.
    public init(locationConfig: PredictiveCacheLocationConfig = .init()) {
        self.locationConfig = locationConfig
    }
}
