import CoreLocation

extension NavigationMapView: CLLocationManagerDelegate {
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateUserLocation(manager)
    }
    
    func updateUserLocation(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            if manager.accuracyAuthorization == .reducedAccuracy {
                reducedAccuracyActivatedMode = true
            } else {
                reducedAccuracyActivatedMode = false
            }
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
