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
        var precedingCoordinates = [LocationCoordinate2D]()
        if stepIndex > 0 {
            precedingCoordinates = legs[legIndex].steps[safe: stepIndex - 1]?.shape?.coordinates ?? []
        }
        if precedingCoordinates.isEmpty, legIndex > 0 {
            precedingCoordinates = legs[legIndex - 1].steps.suffix(2).flatMap { $0.shape?.coordinates ?? [] }
        }
        let precedingPolyline = LineString((precedingCoordinates).reversed())

        
        let followingCoordinates = legs[legIndex].steps[safe: stepIndex]?.shape?.coordinates ?? []
        let followingPolyline = LineString(followingCoordinates)
        
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
