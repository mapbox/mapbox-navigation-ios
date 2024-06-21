
import Foundation

/// Exact ``RoadClasses`` exclusion violation case.
public struct RoadClassExclusionViolation: Equatable, Sendable {
    /// ``RoadClasses`` that were violated at this point.
    public var roadClasses: RoadClasses
    /// Index of a ``Route`` inside ``RouteResponse`` where violation occured.
    public var routeIndex: Int
    /// Index of a ``RouteLeg`` inside ``Route`` where violation occured.
    public var legIndex: Int
    /// Index of a ``RouteStep`` inside ``RouteLeg`` where violation occured.
    public var stepIndex: Int
    /// Index of an `Intersection` inside ``RouteStep`` where violation occured.
    public var intersectionIndex: Int
}
