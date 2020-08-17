import UIKit
import Mapbox
import MapboxCoreNavigation

open class PassiveLocationManager: NSObject, MGLLocationManager {
    public var delegate: MGLLocationManagerDelegate?

    public let dataSource: PassiveLocationDataSource

    public init(dataSource: PassiveLocationDataSource) {
        self.dataSource = dataSource
        super.init()
        dataSource.delegate = self
    }

    public var authorizationStatus: CLAuthorizationStatus {
        CLLocationManager.authorizationStatus()
    }

    public func requestAlwaysAuthorization() {
        dataSource.systemLocationManager.requestAlwaysAuthorization()
    }

    public func requestWhenInUseAuthorization() {
        dataSource.systemLocationManager.requestWhenInUseAuthorization()
    }

    public func startUpdatingLocation() {
        dataSource.startUpdatingLocation()
    }

    public func stopUpdatingLocation() {
        dataSource.systemLocationManager.stopUpdatingLocation()
    }

    public var headingOrientation: CLDeviceOrientation {
        get {
            dataSource.systemLocationManager.headingOrientation
        }
        set {
            dataSource.systemLocationManager.headingOrientation = newValue
        }
    }

    public func startUpdatingHeading() {
        dataSource.systemLocationManager.startUpdatingHeading()
    }

    public func stopUpdatingHeading() {
        dataSource.systemLocationManager.stopUpdatingHeading()
    }

    public func dismissHeadingCalibrationDisplay() {
        dataSource.systemLocationManager.dismissHeadingCalibrationDisplay()
    }
}

extension PassiveLocationManager: PassiveLocationDataSourceDelegate {
    public func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didUpdateLocation location: CLLocation, rawLocation: CLLocation) {
        delegate?.locationManager(self, didUpdate: [location])
    }
    
    public func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didUpdateHeading newHeading: CLHeading) {
        delegate?.locationManager(self, didUpdate: newHeading)
    }
    
    public func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didFailWithError error: Error) {
        delegate?.locationManager(self, didFailWithError: error)
    }
}
