import Foundation
import Mapbox
import Turf

extension Turf.BoundingBox {
    init(coordinateBounds: MGLCoordinateBounds) {
        self.init(coordinateBounds.sw, coordinateBounds.ne)
    }
}

extension LineString {
    var midpoint: CLLocationCoordinate2D? {
        if let distance = self.distance(), let midpoint = self.coordinateFromStart(distance: distance/2) {
            return midpoint
        }

        return nil
    }

    func coordinateAtNormalizedPosition(_ position: Double) -> CLLocationCoordinate2D? {
        if let distance = self.distance(), let point = self.coordinateFromStart(distance: distance * position) {
            return point
        }

        return nil
    }

    func segmentsIntersecting(boundingBox: Turf.BoundingBox) -> [LineString]? {
        var lines = [[CLLocationCoordinate2D]]()
        var currentLine: [CLLocationCoordinate2D]?
        for coordinate in coordinates {
            // see if this coordinate lays within the bounds
            if boundingBox.contains(coordinate) {
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
