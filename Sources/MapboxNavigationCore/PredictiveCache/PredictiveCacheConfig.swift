import MapboxDirections
import MapboxNavigationNative

/// Specifies the content that a predictive cache fetches and how it fetches the content.
public struct PredictiveCacheConfig: Equatable, Sendable {
    /// Predictive cache Navigation related config
    public var predictiveCacheNavigationConfig: PredictiveCacheNavigationConfig = .init()

    /// Predictive cache Map related config
    public var predictiveCacheMapsConfig: PredictiveCacheMapsConfig = .init()

    /// Predictive cache Search domain related config
    public var predictiveCacheSearchConfig: PredictiveCacheSearchConfig? = nil

    /// Creates a new `PredictiveCacheConfig` instance.
    /// - Parameters:
    ///   - predictiveCacheNavigationConfig: Navigation related config.
    ///   - predictiveCacheMapsConfig: Map related config.
    ///   - predictiveCacheSearchConfig: Search related config
    public init(
        predictiveCacheNavigationConfig: PredictiveCacheNavigationConfig = .init(),
        predictiveCacheMapsConfig: PredictiveCacheMapsConfig = .init(),
        predictiveCacheSearchConfig: PredictiveCacheSearchConfig? = nil
    ) {
        self.predictiveCacheNavigationConfig = predictiveCacheNavigationConfig
        self.predictiveCacheMapsConfig = predictiveCacheMapsConfig
        self.predictiveCacheSearchConfig = predictiveCacheSearchConfig
    }
}
