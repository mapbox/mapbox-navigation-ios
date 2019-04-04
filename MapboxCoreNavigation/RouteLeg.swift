import MapboxDirections
import Turf

extension RouteLeg {
    var coordinates: [CLLocationCoordinate2D] {
        return (steps.first?.coordinates ?? []) + steps.dropFirst().flatMap { ($0.coordinates ?? []).dropFirst() }
    }
}
