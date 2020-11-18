import Foundation
import Mapbox
import Turf

extension Turf.BoundingBox {
    init(coordinateBounds: MGLCoordinateBounds) {
        self.init(coordinateBounds.sw, coordinateBounds.ne)
    }
}

extension LineString {
    var simplified: LineString {
        let simplifiedCoordinates = Simplify.simplify(coordinates, tolerance: 0.001)
        return LineString(simplifiedCoordinates)
    }
}
