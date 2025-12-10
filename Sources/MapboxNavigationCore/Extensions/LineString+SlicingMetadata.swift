import Turf

extension LineString {
    struct SlicingMetadata {
        let indexdCoordinate: IndexedCoordinate
        let trailingLineString: LineString

        var coordinate: LocationCoordinate2D {
            indexdCoordinate.coordinate
        }
    }

    func slicingMetadata(at distance: LocationDistance) -> SlicingMetadata? {
        guard let indexedCoordinate = indexedCoordinateFromStart(distance: distance) else {
            return nil
        }

        var remaining = coordinates
        remaining.replaceSubrange(0...indexedCoordinate.index, with: [indexedCoordinate.coordinate])
        return .init(indexdCoordinate: indexedCoordinate, trailingLineString: .init(remaining))
    }
}
