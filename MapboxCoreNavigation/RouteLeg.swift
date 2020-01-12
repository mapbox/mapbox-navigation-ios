import MapboxDirections
import Turf

extension RouteLeg {
    public var shape: LineString {
        return steps.dropFirst().reduce(into: steps.first?.shape ?? LineString([])) { (result, step) in
            result.coordinates += (step.shape?.coordinates ?? []).dropFirst()
        }
    }
}
