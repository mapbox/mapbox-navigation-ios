import Foundation
import Mapbox
import Turf

extension Turf.BoundingBox {
    init(coordinateBounds: MGLCoordinateBounds) {
        self.init(southWest: coordinateBounds.sw, northEast: coordinateBounds.ne)
    }
}
