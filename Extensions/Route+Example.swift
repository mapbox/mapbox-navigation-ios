import Foundation
import MapboxDirections
import Turf

extension Route {
    var tollIntersections: [Intersection]? {
        return nil // Stubbed out until SDK includes new Intersection toll attributes
        #if NavSDK_Includes_Toll_Intersections
        let allSteps = legs.compactMap { return $0.steps }.reduce([], +)

        let allIntersections = allSteps.compactMap { return $0.intersections }.reduce([], +)
        let intersectionsWithTolls = allIntersections.filter { return $0.tollCollection != nil }

        return intersectionsWithTolls
        #endif
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
