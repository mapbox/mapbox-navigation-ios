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

    func stepsIntersecting(boundingBox: Turf.BoundingBox) -> [RouteStep]? {
        let steps = legs.compactMap { return $0.steps }.reduce([], +)
        return steps.filter { return $0.intersects(boundingBox) }
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

    func stepsNotAlong(routeShape: LineString) -> [RouteStep]? {
        let steps = legs.compactMap { return $0.steps }.reduce([], +)
        let stepsNotOnRoute = steps.filter {
            let beginsOn = $0.beginsOn(routeShape)
            if !beginsOn { return true }
            let endsOn = $0.endsOn(routeShape)
            if !endsOn { return true }
            return false
        }
        return stepsNotOnRoute
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

    var initialCoordinate: CLLocationCoordinate2D? {
        return shape?.coordinates.first
    }

    var finalCoordinate: CLLocationCoordinate2D? {
        return shape?.coordinates.last
    }

    func beginsOn(_ line: LineString, tolerance: CLLocationDistance = 10) -> Bool {

        guard let initialCoordinate = initialCoordinate, let closestCoordinate = line.closestCoordinate(to: initialCoordinate) else { return false }


        let distanceAtStart = closestCoordinate.coordinate.distance(to: initialCoordinate)
        return distanceAtStart <= tolerance
    }

    func endsOn(_ line: LineString, tolerance: CLLocationDistance = 10) -> Bool {

        guard let finalCoordinate = finalCoordinate, let closestCoordinate = line.closestCoordinate(to: finalCoordinate) else { return false }


        let distanceAtStart = closestCoordinate.coordinate.distance(to: finalCoordinate)
        return distanceAtStart <= tolerance
    }
}

extension CLLocationCoordinate2D: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}
extension RouteStep: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(shape?.coordinates)
    }
}

extension Array where Element == RouteStep {
    func continuousShapeFromFirstElement() -> LineString? {
        guard count > 0 else { return nil }
        guard count > 1 else { return self[0].shape }
        var continuousLine = [CLLocationCoordinate2D]()
        
        for index in 0...count-2 {
            if let currentStepFinalCoordinate = self[index].finalCoordinate, currentStepFinalCoordinate.distance(to: self[index+1].maneuverLocation) < 10, let coordinates = self[index].shape?.coordinates {
                continuousLine.append(contentsOf: coordinates)
            }
        }

        return LineString(continuousLine)
    }
}

