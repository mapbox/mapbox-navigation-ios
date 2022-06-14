import CoreLocation

extension NavigationMapView: CLLocationManagerDelegate {
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // In case if location changes are not allowed - do not update authorization status and
        // accuracy authorization. Used for testing.
        if !_locationChangesAllowed { return }
        
        if #available(iOS 14.0, *) {
            authorizationStatus = manager.authorizationStatus
            accuracyAuthorization = manager.accuracyAuthorization
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
    }
}
