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

extension Array where Element == RouteStep {
    // Find the longest contiguous series of RouteSteps connected to the first one.
    //
    // tolerance: -- Maximum distance between the end of one RouteStep and the start of the next to still consider them connected. Defaults to 100 meters
    func continuousShape(tolerance: CLLocationDistance = 100) -> LineString? {
        guard count > 0 else { return nil }
        guard count > 1 else { return self[0].shape }
        var continuousLine = [CLLocationCoordinate2D]()
        
        for index in 0...count-2 {
            if let currentStepFinalCoordinate = self[index].shape?.coordinates.last, currentStepFinalCoordinate.distance(to: self[index+1].maneuverLocation) < tolerance, let coordinates = self[index].shape?.coordinates {
                continuousLine.append(contentsOf: coordinates)
            }
        }

        return LineString(continuousLine)
    }
}

