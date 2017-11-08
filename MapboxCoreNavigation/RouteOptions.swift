import MapboxDirections

public extension RouteOptions {
    internal var activityType: CLActivityType {
        switch self.profileIdentifier {
        case MBDirectionsProfileIdentifier.cycling, MBDirectionsProfileIdentifier.walking:
            return .fitness
        default:
            return .automotiveNavigation
        }
    }
    public func without(waypoint: Waypoint) -> RouteOptions {
        let waypointsWithoutSpecified = waypoints.filter { $0 != waypoint }
        let copy = self.copy() as! RouteOptions
        copy.waypoints = waypointsWithoutSpecified
        
        return copy
    }
}
