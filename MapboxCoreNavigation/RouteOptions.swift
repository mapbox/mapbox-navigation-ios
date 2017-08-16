import MapboxDirections

extension RouteOptions {
    var activityType: CLActivityType {
        switch self.profileIdentifier {
        case MBDirectionsProfileIdentifier.cycling, MBDirectionsProfileIdentifier.walking:
            return .fitness
        default:
            return .automotiveNavigation
        }
    }
    
    /**
     Returns an optimal `RouteOptions` for navigation.
     */
    public convenience init(forNavigationWithWaypoints waypoints: [Waypoint], profileIdentifier: MBDirectionsProfileIdentifier? = .automobileAvoidingTraffic) {
        self.init(waypoints: waypoints, profileIdentifier: profileIdentifier)
        
        includesSteps = true
        routeShapeResolution = .full
        attributeOptions = [.congestionLevel]
    }
    
    public convenience init(forNavigationWithCoordinates coordinates: [CLLocationCoordinate2D], profileIdentifier: MBDirectionsProfileIdentifier? = .automobileAvoidingTraffic) {
        self.init(coordinates: coordinates, profileIdentifier: profileIdentifier)
        
        includesSteps = true
        routeShapeResolution = .full
        attributeOptions = [.congestionLevel]
    }
    
    public convenience init(forNavigationWithLocations location: [CLLocation], profileIdentifier: MBDirectionsProfileIdentifier? = .automobileAvoidingTraffic) {
        self.init(locations: location, profileIdentifier: profileIdentifier)
        
        includesSteps = true
        routeShapeResolution = .full
        attributeOptions = [.congestionLevel]
    }
}
