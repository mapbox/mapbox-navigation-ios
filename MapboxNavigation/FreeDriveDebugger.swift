import UIKit
import Mapbox
import MapboxCoreNavigation

open class CLLToMGLConverterLocationManager: NSObject, MGLLocationManager {
    public var delegate: MGLLocationManagerDelegate?

    private let locationManager: FreeDriveLocationManager

    public init(locationManager: FreeDriveLocationManager) {
        self.locationManager = locationManager
        super.init()
        locationManager.delegate = self
    }

    public var authorizationStatus: CLAuthorizationStatus {
        CLLocationManager.authorizationStatus()
    }

    public func requestAlwaysAuthorization() {
        locationManager.systemLocationManager.requestAlwaysAuthorization()
    }

    public func requestWhenInUseAuthorization() {
        locationManager.systemLocationManager.requestWhenInUseAuthorization()
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

    // MARK: CLLocationManagerDelegate

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.locationManager(self, didUpdate: locations)
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        delegate?.locationManager(self, didUpdate: newHeading)
    }

    public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return delegate?.locationManagerShouldDisplayHeadingCalibration(self) ?? false
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.locationManager(self, didFailWithError: error)
    }
}

extension CLLToMGLConverterLocationManager: FreeDriveLocationManagerDelegate {
    public func locationManager(_ manager: FreeDriveLocationManager, didUpdateLocation location: CLLocation, rawLocation: CLLocation) {
        delegate?.locationManager(self, didUpdate: [location])
    }
    
    public func locationManager(_ manager: FreeDriveLocationManager, didUpdateHeading newHeading: CLHeading) {
        delegate?.locationManager(self, didUpdate: newHeading)
    }
    
    public func locationManager(_ manager: FreeDriveLocationManager, didFailWithError error: Error) {
        delegate?.locationManager(self, didFailWithError: error)
    }
}
