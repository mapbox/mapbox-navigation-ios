import Foundation
import Mapbox

extension MGLMapView {
    func coordinateBoundsInset(_ inset: CGSize) -> MGLCoordinateBounds {
        return convert(bounds.insetBy(dx: inset.width, dy: inset.height), toCoordinateBoundsFrom: nil)
    }
}
