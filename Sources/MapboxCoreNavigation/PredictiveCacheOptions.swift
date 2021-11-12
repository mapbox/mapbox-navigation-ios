import MapboxNavigationNative
import MapboxDirections
/**
 Specifies the content that a predictive cache fetches and how it fetches the content.
 
 Pass an instance of this class into the `NavigationOptions(styles:navigationService:voiceController:topBanner:bottomBanner:predictiveCacheOptions:)` initializer or `NavigationMapView.enablePredictiveCaching(options:)` method.
 */
public struct PredictiveCacheOptions {
    
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
    public var maximumConcurrentRequests: UInt32 = 2
    
     /**
     The Authorization & Authentication credentials that are used for this service. If not specified - will be automatically intialized from the token and host from your app's `info.plist`.
     */
    public var credentials: Credentials = .init()
    
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
