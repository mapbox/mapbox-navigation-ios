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

    var tollIntersections: [Intersection]? {
        let allSteps = legs.flatMap { return $0.steps }

        let allIntersections = allSteps.compactMap { return $0.intersections }.reduce([], +)
        let intersectionsWithTolls = allIntersections.filter { return $0.tollCollection != nil }

        return intersectionsWithTolls
    }

    // returns the list of line segments along the route that fall within given bounding box. Returns nil if there are none. Line segments are defined by the route shape coordinates that lay within the bounding box
    func shapes(within: Turf.BoundingBox) -> [LineString]? {
        guard let coordinates = shape?.coordinates else { return nil }
        var lines = [[CLLocationCoordinate2D]]()
        var currentLine: [CLLocationCoordinate2D]?
        for coordinate in coordinates {
            // see if this coordinate lays within the bounds
            if within.contains(coordinate) {
                // if there is no current line segment then start one
                if currentLine == nil {
                    currentLine = [CLLocationCoordinate2D]()
                }

                // append the coordinate to the current line segment
                currentLine?.append(coordinate)
            } else {
                // if there is a current line segment being built then finish it off and reset
                if let currentLine = currentLine {
                    lines.append(currentLine)
                }
                currentLine = nil
            }
        }

        // append any outstanding final segment
        if let currentLine = currentLine {
            lines.append(currentLine)
        }
        currentLine = nil

        // return the segments as LineStrings
        return lines.compactMap { coordinateList -> LineString? in
            return LineString(coordinateList)
        }
    }
}

extension RouteStep {
    func intersects(_ boundingBox: Turf.BoundingBox) -> Bool {
        guard let coordinates = shape?.coordinates else { return false }

        for coordinate in coordinates {
            if boundingBox.contains(coordinate) {
                return true
            }
        }
        return false
    }
}
