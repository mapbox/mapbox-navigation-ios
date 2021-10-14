import CoreLocation
import UIKit
import MapboxCoreNavigation
import MapboxMaps

/**
 An object that notifies a map view when the user’s location changes, minimizing the noise that normally accompanies location updates from a `CLLocationManager` object.
 
 Unlike `Router` classes such as `RouteController` and `LegacyRouteController`, this class operates without a predefined route, matching the user’s location to the road network at large. If your application displays a `MapView` before starting turn-by-turn navigation, call `LocationManager.overrideLocationProvider(with:)` to override default location provider so that the map view always shows the location snapped to the road network. For example, use this class to show the user’s current location as they wander around town.
 
 This class depends on `PassiveLocationManager` to detect the user’s location as it changes. If you want location updates but do not need to display them on a map and do not want a dependency on the MapboxNavigation module, you can use `PassiveLocationManager` instead of this class.
 */
open class PassiveLocationProvider: NSObject, LocationProvider {
    /**
     Initializes the location provider with the given location manager.
     
     - parameter locationManager: A location manager that detects the user’s location as it changes.
     */
    public init(locationManager: PassiveLocationManager) {
        self.locationManager = locationManager
        self.locationProviderOptions = LocationOptions()
        
        super.init()
        locationManager.delegate = self
    }
    
    /**
     The location provider's delegate.
     */
    public weak var delegate: LocationProviderDelegate?
    
    // TODO: Consider replacing with public property.
    public func setDelegate(_ delegate: LocationProviderDelegate) {
        self.delegate = delegate
    }
    
    /**
     The location provider's location manager, which detects the user’s location as it changes.
     */
    public let locationManager: PassiveLocationManager

    public var locationProviderOptions: LocationOptions
    
    // MARK: Heading And Location Updates
    
    public var heading: CLHeading? {
        return locationManager.systemLocationManager.heading
    }
    
    public func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    public func stopUpdatingLocation() {
        locationManager.systemLocationManager.stopUpdatingLocation()
    }

    public var headingOrientation: CLDeviceOrientation {
        get {
            locationManager.systemLocationManager.headingOrientation
        }
        set {
            locationManager.systemLocationManager.headingOrientation = newValue
        }
    }

    public func startUpdatingHeading() {
        locationManager.systemLocationManager.startUpdatingHeading()
    }

    public func stopUpdatingHeading() {
        locationManager.systemLocationManager.stopUpdatingHeading()
    }

    public func dismissHeadingCalibrationDisplay() {
        locationManager.systemLocationManager.dismissHeadingCalibrationDisplay()
    }
    
    // MARK: Authorization Process
    
    public var authorizationStatus: CLAuthorizationStatus {
        CLLocationManager.authorizationStatus()
    }

    public func requestAlwaysAuthorization() {
        locationManager.systemLocationManager.requestAlwaysAuthorization()
    }

    public func requestWhenInUseAuthorization() {
        locationManager.systemLocationManager.requestWhenInUseAuthorization()
    }
    
    public var accuracyAuthorization: CLAccuracyAuthorization {
        if #available(iOS 14.0, *) {
            return locationManager.systemLocationManager.accuracyAuthorization
        } else {
            return .fullAccuracy
        }
    }
    
    @available(iOS 14.0, *)
    public func requestTemporaryFullAccuracyAuthorization(withPurposeKey purposeKey: String) {
        // CLLocationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey:) was introduced in the iOS 14 SDK in Xcode 12, so Xcode 11 doesn’t recognize it.
        let requestTemporaryFullAccuracyAuthorization = Selector(("requestTemporaryFullAccuracyAuthorizationWithPurposeKey:" as NSString) as String)
        guard locationManager.systemLocationManager.responds(to: requestTemporaryFullAccuracyAuthorization) else {
            return
        }
        locationManager.systemLocationManager.perform(requestTemporaryFullAccuracyAuthorization, with: purposeKey)
    }
}

extension PassiveLocationProvider: PassiveLocationManagerDelegate {
    @available(iOS 14.0, *)
    public func passiveLocationManagerDidChangeAuthorization(_ manager: PassiveLocationManager) {
        delegate?.locationProviderDidChangeAuthorization(self)
    }
    
    public func passiveLocationManager(_ manager: PassiveLocationManager, didUpdateLocation location: CLLocation, rawLocation: CLLocation) {
        delegate?.locationProvider(self, didUpdateLocations: [location])
    }
    
    public func passiveLocationManager(_ manager: PassiveLocationManager, didUpdateHeading newHeading: CLHeading) {
        delegate?.locationProvider(self, didUpdateHeading: newHeading)
    }
    
    public func passiveLocationManager(_ manager: PassiveLocationManager, didFailWithError error: Error) {
        delegate?.locationProvider(self, didFailWithError: error)
    }
}
