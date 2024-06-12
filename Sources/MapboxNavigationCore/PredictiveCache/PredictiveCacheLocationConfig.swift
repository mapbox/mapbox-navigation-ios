import MapboxNavigationNative

/// Specifies the content that a predictive cache fetches and how it fetches the content.
public struct PredictiveCacheLocationConfig: Equatable, Sendable {
    /// How far around the user's location caching is going to be performed.
    ///
    /// Defaults to 2000 meters.
    public var currentLocationRadius: CLLocationDistance = 2000

    /// How far around the active route caching is going to be performed (if route is set).
    ///
    /// Defaults to 500 meters.
    public var routeBufferRadius: CLLocationDistance = 500

    /// How far around the destination location caching is going to be performed (if route is set).
    ///
    /// Defaults to 5000 meters.
    public var destinationLocationRadius: CLLocationDistance = 5000

    public init(
        currentLocationRadius: CLLocationDistance = 2000,
        routeBufferRadius: CLLocationDistance = 500,
        destinationLocationRadius: CLLocationDistance = 5000
    ) {
        self.currentLocationRadius = currentLocationRadius
        self.routeBufferRadius = routeBufferRadius
        self.destinationLocationRadius = destinationLocationRadius
    }
}

extension PredictiveLocationTrackerOptions {
    convenience init(_ locationOptions: PredictiveCacheLocationConfig) {
        self.init(
            currentLocationRadius: UInt32(locationOptions.currentLocationRadius),
            routeBufferRadius: UInt32(locationOptions.routeBufferRadius),
            destinationLocationRadius: UInt32(locationOptions.destinationLocationRadius)
        )
    }
}
