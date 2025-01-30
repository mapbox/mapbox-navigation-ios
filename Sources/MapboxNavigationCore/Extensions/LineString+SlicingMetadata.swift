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
        guard let indexedCoordiante = indexedCoordinateFromStart(distance: distance) else {
            return nil
        }

        var remaining = coordinates
        remaining.replaceSubrange(0...indexedCoordiante.index, with: [indexedCoordiante.coordinate])
        return .init(indexdCoordinate: indexedCoordiante, trailingLineString: .init(remaining))
    }
}
