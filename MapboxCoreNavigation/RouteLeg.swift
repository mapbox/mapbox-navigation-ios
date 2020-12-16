import MapboxDirections
import Turf

extension RouteLeg {
    public var shape: LineString {
        return steps.dropFirst().reduce(into: steps.first?.shape ?? LineString([])) { (result, step) in
            result.coordinates += (step.shape?.coordinates ?? []).dropFirst()
        }
    }
    
    /**
     Returns an array of `MapboxStreetsRoadClass` objects for specific leg. `MapboxStreetsRoadClass` will be set to `nil` if it's not present in `Intersection`.
     */
    public var streetsRoadClasses: [MapboxStreetsRoadClass?] {
        // Pick only valid segment indices for specific `Intersection` in `RouteStep`.
        // Array of segment indexes can look like this: [0, 3, 24, 28, 48, 50, 51, 53].
        let segmentIndices = steps.compactMap({ $0.segmentIndicesByIntersection?.compactMap({ $0 }) }).reduce([], +)
        
        // Pick `MapboxStreetsRoadClass` in specific `Intersection` of `RouteStep`.
        // It is expected that number of `segmentIndices` will be equal to number of `streetsRoadClassesInLeg`.
        // Array of `MapboxStreetsRoadClass` can look like this: [Optional(motorway), ... , Optional(motorway), nil]
        let streetsRoadClassesInLeg = steps.compactMap({ $0.intersections?.map({ $0.outletMapboxStreetsRoadClass }) }).reduce([], +)
        
        // Map each `MapboxStreetsRoadClass` to the amount of two adjacent `segmentIndices`.
        // At the end amount of `MapboxStreetsRoadClass` should be equal to the last segment index.
        let streetsRoadClasses = segmentIndices.enumerated().map({ segmentIndices.indices.contains($0.offset + 1) && streetsRoadClassesInLeg.indices.contains($0.offset) ?
                                                                    Array(repeating: streetsRoadClassesInLeg[$0.offset], count: segmentIndices[$0.offset + 1] - segmentIndices[$0.offset]) : [] }).reduce([], +)
        
        return streetsRoadClasses
    }
}
