import MapboxDirections
import Turf

extension RouteLeg {
    var shape: LineString {
        return LineString((steps.first?.shape?.coordinates ?? []) + steps.dropFirst().flatMap { ($0.shape?.coordinates ?? []).dropFirst() })
    }
}
