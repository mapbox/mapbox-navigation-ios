import MapboxDirections
import Turf

extension RouteLeg {
    var coordinates: [CLLocationCoordinate2D] {
        return (steps.first?.shape?.coordinates ?? []) + steps.dropFirst().flatMap { ($0.shape?.coordinates ?? []).dropFirst() }
    }
}
