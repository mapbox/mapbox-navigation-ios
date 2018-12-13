import MapboxDirections
import Turf

extension Route {
    /**
     Returns a polyline extending a given distance in either direction from a given maneuver along the route.
     
     The maneuver is identified by a leg index and step index, in case the route doubles back on itself.
     
     - parameter legIndex: Zero-based index of the leg containing the maneuver.
     - parameter stepIndex: Zero-based index of the step containing the maneuver.
     - parameter distance: Distance by which the resulting polyline extends in either direction from the maneuver.
     - returns: A polyline whose length is twice `distance` and whose centroid is located at the maneuver.
     */
    func polylineAroundManeuver(legIndex: Int, stepIndex: Int, distance: CLLocationDistance) -> Polyline {
        let precedingLegs = legs.prefix(upTo: legIndex)
        let precedingLegCoordinates = precedingLegs.flatMap { $0.steps }.flatMap { $0.coordinates ?? [] }
        
        let precedingSteps = legs[legIndex].steps.prefix(upTo: stepIndex)
        let precedingStepCoordinates = precedingSteps.compactMap { $0.coordinates }.reduce([], +)
        let precedingPolyline = Polyline((precedingLegCoordinates + precedingStepCoordinates).reversed())

        let followingLegs = legs.suffix(from: legIndex).dropFirst()
        let followingLegCoordinates = followingLegs.flatMap { $0.steps }.flatMap { $0.coordinates ?? [] }
        
        let followingSteps = legs[legIndex].steps.suffix(from: stepIndex)
        let followingStepCoordinates = followingSteps.compactMap { $0.coordinates }.reduce([], +)
        let followingPolyline = Polyline(followingStepCoordinates + followingLegCoordinates)
        
        // After trimming, reverse the array so that the resulting polyline proceeds in a forward direction throughout.
        let trimmedPrecedingCoordinates: [CLLocationCoordinate2D]
        if precedingPolyline.coordinates.isEmpty {
            trimmedPrecedingCoordinates = []
        } else {
            trimmedPrecedingCoordinates = precedingPolyline.trimmed(from: precedingPolyline.coordinates[0], distance: distance).coordinates.reversed()
        }
        // Omit the first coordinate, which is already contained in trimmedPrecedingCoordinates.
        let trimmedFollowingCoordinates = followingPolyline.trimmed(from: followingPolyline.coordinates[0], distance: distance).coordinates.suffix(from: 1)
        return Polyline(trimmedPrecedingCoordinates + trimmedFollowingCoordinates)
    }
}
