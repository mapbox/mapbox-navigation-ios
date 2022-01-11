import Foundation
import CoreLocation
import MapboxCoreNavigation
import MapboxMaps

/**
 An object that notifies a map view when the user’s location changes, minimizing the noise that normally accompanies location updates from a `CLLocationManager` object.
 
 If your application displays a `MapView` before starting turn-by-turn navigation, call `LocationManager.overrideLocationProvider(with:)` to override default location provider so that the map view always shows the location snapped to the road network. For example, use this class to show the user’s current location as they wander around town.
 
 This class depends on `NavigationLocationManager` to detect the user’s location as it changes.
 */
open class NavigationLocationProvider: NSObject, LocationProvider, CLLocationManagerDelegate {
    
    // MARK: Managing the Location Data
    
    /**
     The location provider's location manager, which detects the user’s location as it changes.
     */
    public var locationManager: NavigationLocationManager
    
    /**
     Configuration for the `locationManager`.
     */
    public var locationProviderOptions: LocationOptions {
        didSet {
            locationManager.distanceFilter = locationProviderOptions.distanceFilter
            locationManager.desiredAccuracy = locationProviderOptions.desiredAccuracy
            locationManager.activityType = locationProviderOptions.activityType
        }
    }
    
    /**
     Starts the generation of location updates that report the device’s current location.
     */
    public func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    /**
     Stops the generation of location updates.
     */
    public func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    /**
     The location provider's delegate.
     */
    public weak var delegate: LocationProviderDelegate?
    
    public func setDelegate(_ delegate: LocationProviderDelegate) {
        self.delegate = delegate
    }
    
    /**
     The most recently reported heading.
     */
    public var heading: CLHeading? {
        return locationManager.heading
    }
    
    /**
     Specifies a physical device orientation.
     */
    public var headingOrientation: CLDeviceOrientation {
        get {
            locationManager.headingOrientation
        }
        set {
            locationManager.headingOrientation = newValue
        }
    }

    /**
     Starts the generation of heading updates that reports the devices’s current heading.
     */
    public func startUpdatingHeading() {
        locationManager.startUpdatingHeading()
    }
    
    /**
     Stops the generation of heading updates.
     */
    public func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
    }
    
    /**
     Dismisses immediately the heading calibration view from the screen.
     */
    public func dismissHeadingCalibrationDisplay() {
        locationManager.dismissHeadingCalibrationDisplay()
    }
    
    /**
     Initializes the location provider with the given location manager.
     
     - parameter locationManager: A location manager that detects the user’s location as it changes.
     */
    public init(locationManager: NavigationLocationManager) {
        self.locationManager = locationManager
        self.locationProviderOptions = LocationOptions()
        
        super.init()
        locationManager.delegate = self
    }
    
    // MARK: Handling Authorization
    
    /**
     Returns the current localization authorization status.
     */
    public var authorizationStatus: CLAuthorizationStatus {
        CLLocationManager.authorizationStatus()
    }
    
    /**
     Sends the locations update through the delegate to the `MapView` after overriding the `locationProvider` of `MapView`.
     */
    public func didUpdateLocations(locations: [CLLocation]) {
        delegate?.locationProvider(self, didUpdateLocations: locations)
    }
    
    /**
     Returns the current accuracy authorization that the user has granted
     */
    public var accuracyAuthorization: CLAccuracyAuthorization {
        if #available(iOS 14.0, *) {
            return locationManager.accuracyAuthorization
        } else {
            return .fullAccuracy
        }
    }
    
    /**
     Requests permission to use the location services whenever the app is running.
     */
    public func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    /**
     Requests permission to use the location services while the app is in the foreground.
     */
    public func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /**
     Requests temporary permission for precise accuracy
     */
    @available(iOS 14.0, *)
    public func requestTemporaryFullAccuracyAuthorization(withPurposeKey purposeKey: String) {
        let requestTemporaryFullAccuracyAuthorization = Selector(("requestTemporaryFullAccuracyAuthorizationWithPurposeKey:" as NSString) as String)
        guard locationManager.responds(to: requestTemporaryFullAccuracyAuthorization) else {
            return
        }
        locationManager.perform(requestTemporaryFullAccuracyAuthorization, with: purposeKey)
    }
}

