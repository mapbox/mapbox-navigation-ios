import CoreLocation

extension NavigationMapView: CLLocationManagerDelegate {

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if !_locationChangesAllowed { return }
        authorizationStatus = status
    }

    @available(iOS 14.0, *)
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // In case if location changes are not allowed - do not update authorization status and
        // accuracy authorization. Used for testing.
        if !_locationChangesAllowed { return }

        authorizationStatus = manager.authorizationStatus
        accuracyAuthorization = manager.accuracyAuthorization
    }
}
