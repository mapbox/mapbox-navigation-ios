import Foundation
import MapboxMaps
import Turf

extension Turf.BoundingBox {
    init(coordinateBounds: CoordinateBounds) {
        self.init(southWest: coordinateBounds.southwest, northEast: coordinateBounds.northeast)
    }
}
