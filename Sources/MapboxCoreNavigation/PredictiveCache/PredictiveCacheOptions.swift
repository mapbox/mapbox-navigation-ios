import MapboxNavigationNative
import MapboxDirections
/**
 Specifies the content that a predictive cache fetches and how it fetches the content.
 
 Pass an instance of this class into the `NavigationOptions(styles:navigationService:voiceController:topBanner:bottomBanner:predictiveCacheOptions:)` initializer or `NavigationMapView.enablePredictiveCaching(options:)` method.
 */
public struct PredictiveCacheOptions {

    /**
     Predictive cache Navigation related options
    */
    public var predictiveCacheNavigationOptions: PredictiveCacheNavigationOptions = .init()

    /**
     Predictive cache Map related options
     */
    public var predictiveCacheMapsOptions: PredictiveCacheMapsOptions = .init()
    
    /**
     How far around the user's location caching is going to be performed.
     
     Defaults to 2000 meters.
     */
    @available(*, deprecated, message: "Use `predictiveCacheNavigationOptions` and `predictiveCacheMapsOptions` instead.")
    public var currentLocationRadius: CLLocationDistance {
        get {
            predictiveCacheNavigationOptions.locationOptions.currentLocationRadius
        }
        set {
            predictiveCacheNavigationOptions.locationOptions.currentLocationRadius = newValue
            predictiveCacheMapsOptions.locationOptions.currentLocationRadius = newValue
        }
    }
    
    /**
     How far around the active route caching is going to be performed (if route is set).
     
     Defaults to 500 meters.
     */
    @available(*, deprecated, message: "Use `predictiveCacheNavigationOptions` and `predictiveCacheMapsOptions` instead.")
    public var routeBufferRadius: CLLocationDistance {
        get {
            predictiveCacheNavigationOptions.locationOptions.routeBufferRadius
        }
        set {
            predictiveCacheNavigationOptions.locationOptions.routeBufferRadius = newValue
            predictiveCacheMapsOptions.locationOptions.routeBufferRadius = newValue
        }
    }
    
    /**
     How far around the destination location caching is going to be performed (if route is set).
     
     Defaults to 5000 meters.
     */
    @available(*, deprecated, message: "Use `predictiveCacheNavigationOptions` and `predictiveCacheMapsOptions` instead.")
    public var destinationLocationRadius: CLLocationDistance {
        get {
            predictiveCacheNavigationOptions.locationOptions.destinationLocationRadius
        }
        set {
            predictiveCacheNavigationOptions.locationOptions.destinationLocationRadius = newValue
            predictiveCacheMapsOptions.locationOptions.destinationLocationRadius = newValue
        }
    }
    
    /**
     Maxiumum amount of concurrent requests, which will be used for caching.
     
     Defaults to 2 concurrent requests.
     */
    @available(*, deprecated, message: "Use `predictiveCacheMapsOptions.maximumConcurrentRequests` instead.")
    public var maximumConcurrentRequests: UInt32 {
        get {
            predictiveCacheMapsOptions.maximumConcurrentRequests
        }
        set {
            predictiveCacheMapsOptions.maximumConcurrentRequests = newValue
        }
    }
    
     /**
     The Authorization & Authentication credentials that are used for this service. If not specified - will be automatically intialized from the token and host from your app's `info.plist`.
     */
    public var credentials: Credentials = .init()
    
    public init() {
        // No-op
    }
}
