import CoreLocation

extension CLLocation {
    
    /**
     Returns distance between two coordinates.
     */
    class func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let fromlocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        
        return fromlocation.distance(from: toLocation)
    }
}
