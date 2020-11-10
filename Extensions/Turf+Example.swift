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
}
