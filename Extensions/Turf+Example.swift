import Foundation
import Mapbox
import Turf

extension Turf.BoundingBox {
    init(coordinateBounds: MGLCoordinateBounds) {
        self.init(coordinateBounds.sw, coordinateBounds.ne)
    }
}
