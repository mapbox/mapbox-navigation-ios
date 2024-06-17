import CoreLocation
import MapboxDirections
import Turf

extension Route {
    func leg(containing step: RouteStep) -> RouteLeg? {
        return legs.first { $0.steps.contains(step) }
    }

    /// Returns true if both the legIndex and stepIndex are valid in the route.
    func containsStep(at legIndex: Int, stepIndex: Int) -> Bool {
        return legs[safe: legIndex]?.steps.indices.contains(stepIndex) ?? false
    }
}
