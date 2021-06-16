import Foundation
import CoreLocation
import MapboxCoreNavigation
import MapboxMaps

public class NavigationLocationProvider: NSObject, LocationProvider, CLLocationManagerDelegate {
    /**
     The location provider's location manager, which detects the user’s location as it changes.
     */
    private var locationManager: NavigationLocationManager
    
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
    private weak var delegate: LocationProviderDelegate?
    
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
    
    //TODO, if no heading, form a heading from the location.course
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
     Initializes the location provider with the `NavigationLocationManager`.
     */
    public override init() {
        locationManager = NavigationLocationManager()
        locationProviderOptions = LocationOptions()
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

