import CoreLocation
import MapboxDirections

extension RouteOptions {
    var activityType: CLActivityType {
        switch profileIdentifier {
        case .cycling, .walking:
            return .fitness
        default:
            return .otherNavigation
        }
    }

    /// Returns a tuple containing the waypoints along the leg at the given index and the waypoints that separate
    /// subsequent legs.
    ///
    /// The first element of the tuple includes the leg’s source but not its destination.
    func waypoints(fromLegAt legIndex: Int) -> ([Waypoint], [Waypoint]) {
        // The first and last waypoints always separate legs. Make exceptions for these waypoints instead of modifying
        // them by side effect.
        let legSeparators = waypoints.filterKeepingFirstAndLast { $0.separatesLegs }
        let viaPointsByLeg = waypoints.splitExceptAtStartAndEnd(omittingEmptySubsequences: false) { $0.separatesLegs }
            .dropFirst() // No leg precedes first separator.

        let reconstitutedWaypoints = zip(legSeparators, viaPointsByLeg).dropFirst(legIndex).map { [$0.0] + $0.1 }
        let legWaypoints = reconstitutedWaypoints.first ?? []
        let subsequentWaypoints = reconstitutedWaypoints.dropFirst()
        return (legWaypoints, subsequentWaypoints.flatMap { $0 })
    }
}

extension RouteOptions {
    /// Returns a copy of the route options by roundtripping through JSON.
    ///
    /// - Throws: An `EncodingError` or `DecodingError` if the route options could not be roundtripped through JSON.
    func copy() throws -> Self {
        // TODO: remove this method when changed to value type.
        // Work around <https://github.com/mapbox/mapbox-directions-swift/issues/564>.
        let encodedOptions = try JSONEncoder().encode(self)
        return try JSONDecoder().decode(type(of: self), from: encodedOptions)
    }
}

extension Array {
    /// - seealso: `Array.filter(_:)`
    public func filterKeepingFirstAndLast(_ isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
        return try enumerated().filter {
            try isIncluded($0.element) || $0.offset == 0 || $0.offset == indices.last
        }.map(\.element)
    }

    /// - seealso: `Array.split(maxSplits:omittingEmptySubsequences:whereSeparator:)`
    public func splitExceptAtStartAndEnd(
        maxSplits: Int = .max,
        omittingEmptySubsequences: Bool = true,
        whereSeparator isSeparator: (Element) throws -> Bool
    ) rethrows -> [ArraySlice<Element>] {
        return try enumerated().split(maxSplits: maxSplits, omittingEmptySubsequences: omittingEmptySubsequences) {
            try isSeparator($0.element) || $0.offset == 0 || $0.offset == indices.last
        }.map { $0.map(\.element).suffix(from: 0) }
    }
}
