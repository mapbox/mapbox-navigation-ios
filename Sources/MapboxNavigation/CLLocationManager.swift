import CoreLocation

extension CLLocationManager {
    
    /**
     Allows to detect whether application is authorized to use location services.
     
     - returns: `true` if authorized to use location services, `false` otherwise.
     */
    func isAuthorized() -> Bool {
        let currentAuthorizationStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            currentAuthorizationStatus = authorizationStatus
        } else {
            currentAuthorizationStatus = CLLocationManager.authorizationStatus()
        }
        
        let allowedAuthorizationStatuses: [CLAuthorizationStatus] = [
            .authorizedAlways,
            .authorizedWhenInUse
        ]
        
        if allowedAuthorizationStatuses.contains(currentAuthorizationStatus) {
            return true
        }
        
        return false
    }
}
