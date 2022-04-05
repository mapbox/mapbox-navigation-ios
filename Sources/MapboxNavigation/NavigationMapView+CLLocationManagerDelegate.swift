import CoreLocation

extension NavigationMapView: CLLocationManagerDelegate {
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateUserLocation(manager)
    }
    
    func updateUserLocation(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            // `UserHaloCourseView` will be applied in two cases:
            // 1. When user explicitly sets `NavigationMapView.reducedAccuracyActivatedMode` to `true`.
            // 2. When user disables `Precise Location` property in the settings of current application.
            let shouldApply = reducedAccuracyActivatedMode || manager.accuracyAuthorization == .reducedAccuracy
            applyReducedAccuracyMode(shouldApply: shouldApply)
        }
        
        if locationManager.isAuthorized() {
            setupUserLocation()
        } else {
            mapView.location.options.puckType = nil
            reducedAccuracyUserHaloCourseView = nil
            
            if let currentCourseView = mapView.viewWithTag(NavigationMapView.userCourseViewTag) {
                currentCourseView.removeFromSuperview()
            }
        }
    }
}
