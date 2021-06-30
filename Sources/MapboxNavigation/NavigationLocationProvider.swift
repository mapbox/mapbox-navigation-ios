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
    /**
     The location provider's location manager, which detects the user’s location as it changes.
     */
    public var locationManager: NavigationLocationManager
    
    public var locationProviderOptions: LocationOptions {
        didSet {
            locationManager.distanceFilter = locationProviderOptions.distanceFilter
            locationManager.desiredAccuracy = locationProviderOptions.desiredAccuracy
            locationManager.activityType = locationProviderOptions.activityType
        }
    }
    
    /**
     The location provider's delegate.
     */
    public weak var delegate: LocationProviderDelegate?
    
    public var authorizationStatus: CLAuthorizationStatus {
        CLLocationManager.authorizationStatus()
    }
    
    public var accuracyAuthorization: CLAccuracyAuthorization {
        if #available(iOS 14.0, *) {
            return locationManager.accuracyAuthorization
        } else {
            return .fullAccuracy
        }
    }
    
    public var heading: CLHeading? {
        return locationManager.heading
    }
    
    public var headingOrientation: CLDeviceOrientation {
        get {
            locationManager.headingOrientation
        }
        set {
            locationManager.headingOrientation = newValue
        }
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
    
    public func setDelegate(_ delegate: LocationProviderDelegate) {
        self.delegate = delegate
    }
    
    public func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    public func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    @available(iOS 14.0, *)
    public func requestTemporaryFullAccuracyAuthorization(withPurposeKey purposeKey: String) {
        let requestTemporaryFullAccuracyAuthorization = Selector(("requestTemporaryFullAccuracyAuthorizationWithPurposeKey:" as NSString) as String)
        guard locationManager.responds(to: requestTemporaryFullAccuracyAuthorization) else {
            return
        }
        locationManager.perform(requestTemporaryFullAccuracyAuthorization, with: purposeKey)
    }
    
    public func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    public func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    public func startUpdatingHeading() {
        locationManager.startUpdatingHeading()
    }
    
    public func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
    }
    
    public func dismissHeadingCalibrationDisplay() {
        locationManager.dismissHeadingCalibrationDisplay()
    }
}

