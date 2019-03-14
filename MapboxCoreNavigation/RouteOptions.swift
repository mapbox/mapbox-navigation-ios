import MapboxDirections

extension RouteOptions {
    internal var activityType: CLActivityType {
        switch self.profileIdentifier {
        case MBDirectionsProfileIdentifier.cycling, MBDirectionsProfileIdentifier.walking:
            return .fitness
        default:
            return .automotiveNavigation
        }
    }
    
    /**
     Returns a copy of RouteOptions without the specified waypoint.
     
     - parameter waypoint: the Waypoint to exclude.
     - returns: a copy of self excluding the specified waypoint.
     */
    public func without(waypoint: Waypoint) -> RouteOptions {
        let waypointsWithoutSpecified = waypoints.filter { $0 != waypoint }
        let copy = self.copy() as! RouteOptions
        copy.waypoints = waypointsWithoutSpecified
        
        return copy
    }
    
    /**
     Returns a tuple containing the waypoints along the leg at the given index and the waypoints that separate subsequent legs.
     
     The first element of the tuple includes the leg’s source but not its destination.
     */
    func waypoints(fromLegAt legIndex: Int) -> ([Waypoint], [Waypoint]) {
        // The first and last waypoints always separate legs. Make exceptions for these waypoints instead of modifying them by side effect.
        let legSeparators = waypoints.filterKeepingFirstAndLast { $0.separatesLegs }
        let viaPointsByLeg = waypoints.splitExceptAtStartAndEnd(omittingEmptySubsequences: false) { $0.separatesLegs }
            .dropFirst() // No leg precedes first separator.
        
        let reconstitutedWaypoints = zip(legSeparators, viaPointsByLeg).dropFirst(legIndex).map { [$0.0] + $0.1 }
        let legWaypoints = reconstitutedWaypoints.first ?? []
        let subsequentWaypoints = reconstitutedWaypoints.dropFirst()
        return (legWaypoints, subsequentWaypoints.flatMap { $0 })
    }
}

extension Array {
    /**
     - seealso: Array.filter(_:)
     */
    public func filterKeepingFirstAndLast(_ isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
        return try enumerated().filter {
            try isIncluded($0.element) || $0.offset == 0 || $0.offset == indices.last
        }.map { $0.element }
    }
    
    /**
     - seealso: Array.split(maxSplits:omittingEmptySubsequences:whereSeparator:)
     */
    public func splitExceptAtStartAndEnd(maxSplits: Int = .max, omittingEmptySubsequences: Bool = true, whereSeparator isSeparator: (Element) throws -> Bool) rethrows -> [ArraySlice<Element>] {
        return try enumerated().split(maxSplits: maxSplits, omittingEmptySubsequences: omittingEmptySubsequences) {
            try isSeparator($0.element) || $0.offset == 0 || $0.offset == indices.last
        }.map { $0.map { $0.element }.suffix(from: 0) }
    }
}
