import CoreLocation
import Turf

@_spi(MapboxInternal)
extension Array where Iterator.Element == CLLocationCoordinate2D {
    public func sliced(
        from: CLLocationCoordinate2D? = nil,
        to: CLLocationCoordinate2D? = nil
    ) -> [CLLocationCoordinate2D] {
        return LineString(self).sliced(from: from, to: to)?.coordinates ?? []
    }

    public func distance(
        from: CLLocationCoordinate2D? = nil,
        to: CLLocationCoordinate2D? = nil
    ) -> CLLocationDistance? {
        return LineString(self).distance(from: from, to: to)
    }

    public func trimmed(
        from: CLLocationCoordinate2D? = nil,
        distance: CLLocationDistance
    ) -> [CLLocationCoordinate2D] {
        if let fromCoord = from ?? first {
            return LineString(self).trimmed(from: fromCoord, distance: distance)?.coordinates ?? []
        } else {
            return []
        }
    }

    public var centerCoordinate: CLLocationCoordinate2D {
        let avgLat = map(\.latitude).reduce(0.0, +) / Double(count)
        let avgLng = map(\.longitude).reduce(0.0, +) / Double(count)

        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLng)
    }
}
