import CoreLocation
import MapboxDirections
import Turf

extension Match {
    /**
     Returns a polyline extending a given distance in either direction from a given maneuver along the route.
     
     The maneuver is identified by a leg index and step index, in case the route doubles back on itself.
     
     - parameter legIndex: Zero-based index of the leg containing the maneuver.
     - parameter stepIndex: Zero-based index of the step containing the maneuver.
     - parameter distance: Distance by which the resulting polyline extends in either direction from the maneuver.
     - returns: A polyline whose length is twice `distance` and whose centroid is located at the maneuver.
     */
    func polylineAroundManeuver(legIndex: Int, stepIndex: Int, distance: CLLocationDistance) -> LineString {
        let precedingLegs = legs.prefix(upTo: legIndex)
        let precedingLegCoordinates = precedingLegs.flatMap { $0.steps }.flatMap { $0.shape?.coordinates ?? [] }
        
        let precedingSteps = legs[legIndex].steps.prefix(upTo: stepIndex)
        let precedingStepCoordinates = precedingSteps.compactMap { $0.shape?.coordinates }.reduce([], +)
        let precedingPolyline = LineString((precedingLegCoordinates + precedingStepCoordinates).reversed())

        let followingLegs = legs.suffix(from: legIndex).dropFirst()
        let followingLegCoordinates = followingLegs.flatMap { $0.steps }.flatMap { $0.shape?.coordinates ?? [] }
        
        let followingSteps = legs[legIndex].steps.suffix(from: stepIndex)
        let followingStepCoordinates = followingSteps.compactMap { $0.shape?.coordinates }.reduce([], +)
        let followingPolyline = LineString(followingStepCoordinates + followingLegCoordinates)
        
        // After trimming, reverse the array so that the resulting polyline proceeds in a forward direction throughout.
        let trimmedPrecedingCoordinates: [CLLocationCoordinate2D]
        if precedingPolyline.coordinates.isEmpty {
            trimmedPrecedingCoordinates = []
        } else {
            trimmedPrecedingCoordinates = precedingPolyline.trimmed(from: precedingPolyline.coordinates[0], distance: distance)!.coordinates.reversed()
        }
        // Omit the first coordinate, which is already contained in trimmedPrecedingCoordinates.
        if followingPolyline.coordinates.isEmpty {
            return LineString(trimmedPrecedingCoordinates)
        } else {
            return LineString(trimmedPrecedingCoordinates + followingPolyline.trimmed(from: followingPolyline.coordinates[0], distance: distance)!.coordinates.suffix(from: 1))
        }
    }
}
