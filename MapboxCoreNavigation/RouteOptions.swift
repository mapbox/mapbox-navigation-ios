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
    public var preferredOptions: RouteOptions {
        includesSteps = true
        routeShapeResolution = .full
        profileIdentifier = .automobileAvoidingTraffic
        
        // Adding the optional attribute `.congestionLevel` ensures the route line will show the congestion along the route line
        attributeOptions = [.congestionLevel]
        
        return self
    }
}
