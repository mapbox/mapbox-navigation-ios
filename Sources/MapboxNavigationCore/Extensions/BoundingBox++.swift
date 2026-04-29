import CoreGraphics
import Turf

extension BoundingBox {
    /// Returns zoom level inside of specific `CGSize`, in which `BoundingBox` was fit to.
    func zoomLevel(fitTo size: CGSize) -> Double {
        let latitudeFraction = (northEast.latitude.toRadians() - southWest.latitude.toRadians()) / .pi
        let longitudeDiff = northEast.longitude - southWest.longitude
        let longitudeFraction = ((longitudeDiff < 0) ? (longitudeDiff + 360) : longitudeDiff) / 360
        let latitudeZoom = log(Double(size.height) / 512.0 / latitudeFraction) / M_LN2
        let longitudeZoom = log(Double(size.width) / 512.0 / longitudeFraction) / M_LN2

        return min(latitudeZoom, longitudeZoom, 21.0)
    }
}
