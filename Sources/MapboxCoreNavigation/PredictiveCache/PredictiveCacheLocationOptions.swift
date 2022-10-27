import MapboxNavigationNative

/**
 Specifies the content that a predictive cache fetches and how it fetches the content.
 */
public struct PredictiveCacheLocationOptions {
    
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
    
    public init() {
        // No-op
    }
}

extension PredictiveLocationTrackerOptions {
    
    convenience init(_ locationOptions: PredictiveCacheLocationOptions) {
        self.init(currentLocationRadius: UInt32(locationOptions.currentLocationRadius),
                  routeBufferRadius: UInt32(locationOptions.routeBufferRadius),
                  destinationLocationRadius: UInt32(locationOptions.destinationLocationRadius))
    }
}
