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
    public convenience init(forNavigationWith waypoints: [Waypoint], profileIdentifier: MBDirectionsProfileIdentifier? = .automobileAvoidingTraffic) {
        self.init(waypoints: waypoints, profileIdentifier: profileIdentifier)
        
        includesSteps = true
        routeShapeResolution = .full
        
        // Adding the optional attribute `.congestionLevel` ensures the route line will show the congestion along the route line
        attributeOptions = [.congestionLevel]
    }
}
