import CoreLocation
import MapboxDirections
import Turf

extension Route {
    /**
     Returns a polyline extending a given distance in either direction from a given maneuver along the route.
     
     The maneuver is identified by a leg index and step index, in case the route doubles back on itself.
     
     - parameter legIndex: Zero-based index of the leg containing the maneuver.
     - parameter stepIndex: Zero-based index of the step containing the maneuver.
     - parameter distance: Distance by which the resulting polyline extends in either direction from the maneuver.
     - returns: A polyline whose length is twice `distance` and whose centroid is located at the maneuver.
     */
    func polylineAroundManeuver(legIndex: Int, stepIndex: Int, distance: CLLocationDistance) -> LineString {
        let precedingLegs = legs.prefix(upTo: legIndex)
        let precedingLegCoordinates = precedingLegs.flatMap { $0.steps }.flatMap { $0.shape?.coordinates ?? [] }
        
        let precedingSteps = legs[legIndex].steps.prefix(upTo: stepIndex)
        let precedingStepCoordinates = precedingSteps.compactMap { $0.shape?.coordinates }.reduce([], +)
        let precedingPolyline = LineString((precedingLegCoordinates + precedingStepCoordinates).reversed())

        let followingLegs = legs.suffix(from: legIndex).dropFirst()
        let followingLegCoordinates = followingLegs.flatMap { $0.steps }.flatMap { $0.shape?.coordinates ?? [] }
        
        let followingSteps = legs[legIndex].steps.suffix(from: stepIndex)
        let followingStepCoordinates = followingSteps.compactMap { $0.shape?.coordinates }.reduce([], +)
        let followingPolyline = LineString(followingStepCoordinates + followingLegCoordinates)
        
        // After trimming, reverse the array so that the resulting polyline proceeds in a forward direction throughout.
        let trimmedPrecedingCoordinates: [CLLocationCoordinate2D]
        if precedingPolyline.coordinates.isEmpty {
            trimmedPrecedingCoordinates = []
        } else {
            trimmedPrecedingCoordinates = precedingPolyline.trimmed(from: precedingPolyline.coordinates[0], distance: distance)!.coordinates.reversed()
        }
        // Omit the first coordinate, which is already contained in trimmedPrecedingCoordinates.
        if followingPolyline.coordinates.isEmpty {
            return LineString(trimmedPrecedingCoordinates)
        } else {
            return LineString(trimmedPrecedingCoordinates + followingPolyline.trimmed(from: followingPolyline.coordinates[0], distance: distance)!.coordinates.suffix(from: 1))
        }
    }
    
    func congestionFeatures(legIndex: Int? = nil,
                            isAlternativeRoute: Bool = false,
                            roadClassesWithOverriddenCongestionLevels: Set<MapboxStreetsRoadClass>? = nil) -> [Feature] {
        guard let coordinates = shape?.coordinates, let shape = shape else { return [] }
        var features: [Feature] = []
        
        for (index, leg) in legs.enumerated() {
            let legFeatures: [Feature]
            
            if let congestionLevels = leg.segmentCongestionLevels, congestionLevels.count < coordinates.count {
                // The last coordinate of the preceding step, is shared with the first coordinate of the next step, we don't need both.
                let legCoordinates: [CLLocationCoordinate2D] = leg.steps.enumerated().reduce([]) { allCoordinates, current in
                    let index = current.offset
                    let step = current.element
                    let stepCoordinates = step.shape!.coordinates
                    
                    return index == 0 ? stepCoordinates : allCoordinates + stepCoordinates.suffix(from: 1)
                }
                
                let mergedCongestionSegments = legCoordinates.combined(congestionLevels,
                                                                       streetsRoadClasses: leg.streetsRoadClasses,
                                                                       roadClassesWithOverriddenCongestionLevels: roadClassesWithOverriddenCongestionLevels)
                
                legFeatures = mergedCongestionSegments.map { (congestionSegment: CongestionSegment) -> Feature in
                    var feature = Feature(LineString(congestionSegment.0))
                    feature.properties = [
                        CongestionAttribute: String(describing: congestionSegment.1),
                        "isAlternativeRoute": isAlternativeRoute,
                        CurrentLegAttribute: (legIndex != nil) ? index == legIndex : index == 0
                    ]
                    
                    return feature
                }
            } else {
                var feature = Feature(LineString(shape.coordinates))
                feature.properties = [
                    "isAlternativeRoute": isAlternativeRoute,
                    CurrentLegAttribute: (legIndex != nil) ? index == legIndex : index == 0
                ]
                legFeatures = [feature]
            }
            
            features.append(contentsOf: legFeatures)
        }
        
        return features
    }
    
    func identifier(_ routeLineType: RouteLineType) -> String {
        // To have the ability to reliably distinguish `Route` objects their memory addresses are used
        // as identifiers. `Route.routeIdentifier` is not enough in this case because it'll be the same
        // for all routes requested via `Directions.calculate(_:completionHandler:)`.
        let identifier = Unmanaged.passUnretained(self).toOpaque()
    
        switch routeLineType {
        
        case .source(isMainRoute: let isMainRoute, isSourceCasing: let isSourceCasing):
            return "\(identifier).\(isMainRoute ? "main" : "alternative").\(isSourceCasing ? "source_casing" : "source")"
        case .route(isMainRoute: let isMainRoute):
            return "\(identifier).\(isMainRoute ? "main" : "alternative").route_line"
        case .routeCasing(isMainRoute: let isMainRoute):
            return "\(identifier).\(isMainRoute ? "main" : "alternative").route_line_casing"
        }
    }
    
    func leg(containing step: RouteStep) -> RouteLeg? {
        return legs.first { $0.steps.contains(step) }
    }
}
