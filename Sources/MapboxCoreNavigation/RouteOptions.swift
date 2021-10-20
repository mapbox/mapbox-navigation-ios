import CoreLocation
import MapboxDirections

extension RouteOptions {
    internal var activityType: CLActivityType {
        switch self.profileIdentifier {
        case .cycling, .walking:
            return .fitness
        default:
            return .automotiveNavigation
        }
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
    
    /**
     Returns a copy of the route options by roundtripping through JSON.
     
     - throws: An `EncodingError` or `DecodingError` if the route options could not be roundtripped through JSON.
     */
    func copy() throws -> Self {
        // Work around <https://github.com/mapbox/mapbox-directions-swift/issues/564>.
        let encodedOptions = try JSONEncoder().encode(self)
        return try JSONDecoder().decode(type(of: self), from: encodedOptions)
    }
    
    /**
     Returns a copy of the route options without the specified waypoint.
     
     If the route options is unable to copy itself by round-tripping through JSON, this method mutates the receiver’s `waypoints` as a last resort.
     
     - parameter waypoint: the Waypoint to exclude.
     - returns: a copy of self excluding the specified waypoint.
     */
    public func without(_ waypoint: Waypoint) -> RouteOptions {
        let waypointsWithoutSpecified = waypoints.filter { $0 != waypoint }
        let copy: RouteOptions
        do {
            copy = try self.copy()
        } catch {
            copy = self
        }
        copy.waypoints = waypointsWithoutSpecified
        
        return copy
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
