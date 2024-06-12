import MapboxDirections
import MapboxNavigationNative

/// Specifies the content that a predictive cache fetches and how it fetches the content.
public struct PredictiveCacheConfig: Equatable, Sendable {
    /// Predictive cache Navigation related config
    public var predictiveCacheNavigationConfig: PredictiveCacheNavigationConfig = .init()

    /// Predictive cache Map related config
    public var predictiveCacheMapsConfig: PredictiveCacheMapsConfig = .init()

    /// Creates a new `PredictiveCacheConfig` instance.
    /// - Parameters:
    ///   - predictiveCacheNavigationConfig: Navigation related config.
    ///   - predictiveCacheMapsConfig: Map related config.
    public init(
        predictiveCacheNavigationConfig: PredictiveCacheNavigationConfig = .init(),
        predictiveCacheMapsConfig: PredictiveCacheMapsConfig = .init()
    ) {
        self.predictiveCacheNavigationConfig = predictiveCacheNavigationConfig
        self.predictiveCacheMapsConfig = predictiveCacheMapsConfig
    }
}
