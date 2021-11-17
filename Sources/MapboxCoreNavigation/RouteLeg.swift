import MapboxDirections
import Turf

extension RouteLeg {
    public var shape: LineString {
        return steps.dropFirst().reduce(into: steps.first?.shape ?? LineString([])) { (result, step) in
            result.coordinates += (step.shape?.coordinates ?? []).dropFirst()
        }
    }
    
    func mapIntersectionsAttributes<T>(_ attributeTransform: (Intersection) -> T) -> [T] {
        // Pick only valid segment indices for specific `Intersection` in `RouteStep`.
        // Array of segment indexes can look like this: [0, 3, 24, 28, 48, 50, 51, 53].
        let segmentIndices = steps.compactMap({ $0.segmentIndicesByIntersection?.compactMap({ $0 }) }).reduce([], +)
        
        // Pick selected attribute by `attributeTransform` in specific `Intersection` of `RouteStep`.
        // It is expected that number of `segmentIndices` will be equal to number of `attributesInLeg`.
        // Array may include optionals and nil values.
        let attributesInLeg = steps.compactMap({ $0.intersections?.map(attributeTransform) }).reduce([], +)
        
        // Map each selected attribute to the amount of two adjacent `segmentIndices`.
        // At the end amount of attributes should be equal to the last segment index.
        let streetsRoadClasses = segmentIndices.enumerated().map {
            segmentIndices.indices.contains($0.offset + 1) && attributesInLeg.indices.contains($0.offset) ?
                Array(repeating: attributesInLeg[$0.offset], count: segmentIndices[$0.offset + 1] - segmentIndices[$0.offset]) : []
            
        }.reduce([], +)
        
        return streetsRoadClasses
    }
    
    /**
     Returns an array of `MapboxStreetsRoadClass` objects for specific leg. `MapboxStreetsRoadClass` will be set to `nil` if it's not present in `Intersection`.
     */
    public var streetsRoadClasses: [MapboxStreetsRoadClass?] {
        return mapIntersectionsAttributes { $0.outletMapboxStreetsRoadClass }
    }
    
    /**
     Returns an array of `RoadClasses` objects for specific leg. `RoadClasses` will be set to `nil` if it's not present in `Intersection`.
     */
    public var roadClasses: [RoadClasses?] {
        return mapIntersectionsAttributes { $0.outletRoadClasses }
    }
}
