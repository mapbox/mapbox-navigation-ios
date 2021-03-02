import MapboxNavigationNative

/**
 `PredictiveCacheOptions` controls various configurations for a `Predictive Caching` mechanic.
 */
public class PredictiveCacheOptions {
    
    /**
     How far around the user's location caching is going to be performed.
     
     Defaults to 2000 meters.
     */
    public var currentLocationRadius: CLLocationDistance = 2000
    
    /**
     How far around the active route caching is going to be performed (if route is set).
     
     Defaults to 500 meters.
     */
    public var routeBufferRadius: CLLocationDistance = 500
    
    /**
     How far around the destination location caching is going to be performed (if route is set).
     
     Defaults to 5000 meters.
     */
    public var destinationLocationRadius: CLLocationDistance = 5000
    
    /**
     Maxiumum amount of concurrent requests, which will be used for caching.
     
     Defaults to 2 concurrent requests.
     */
    public var maxConcurrentRequests: UInt32 = 2
    
    public init() {
        // No-op
    }
}

extension PredictiveLocationTrackerOptions {
    
    convenience init(_ predictiveCacheOptions: PredictiveCacheOptions) {
        self.init(currentLocationRadius: UInt32(predictiveCacheOptions.currentLocationRadius),
                  routeBufferRadius: UInt32(predictiveCacheOptions.routeBufferRadius),
                  destinationLocationRadius: UInt32(predictiveCacheOptions.destinationLocationRadius))
    }
}
