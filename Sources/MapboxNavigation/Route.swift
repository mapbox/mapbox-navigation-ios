import CoreLocation
import MapboxCoreNavigation
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
    
    func restrictedRoadsFeatures() -> [Feature] {
        guard shape != nil else { return [] }
        
        var hasRestriction = false
        var features: [Feature] = []
        
        for leg in legs {
            let legRoadClasses = leg.roadClasses
            
            // The last coordinate of the preceding step, is shared with the first coordinate of the next step, we don't need both.
            let legCoordinates: [CLLocationCoordinate2D] = leg.steps.enumerated().reduce([]) { allCoordinates, current in
                let index = current.offset
                let step = current.element
                let stepCoordinates = step.shape!.coordinates
                
                return index == 0 ? stepCoordinates : allCoordinates + stepCoordinates.suffix(from: 1)
            }
            
            let mergedRoadClasses = legCoordinates.combined(legRoadClasses,
                                                            combiningRoadClasses: .restricted)
            
            features.append(contentsOf: mergedRoadClasses.map { (roadClassesSegment: RoadClassesSegment) -> Feature in
                var feature = Feature(geometry: .lineString(LineString(roadClassesSegment.0)))
                feature.properties = [
                    RestrictedRoadClassAttribute: .boolean(roadClassesSegment.1 == .restricted),
                ]
                
                if !hasRestriction && roadClassesSegment.1 == .restricted {
                    hasRestriction = true
                }
                
                return feature
            })
        }
        
        return hasRestriction ? features : []
    }
    
    func congestionFeatures(legIndex: Int? = nil,
                            roadClassesWithOverriddenCongestionLevels: Set<MapboxStreetsRoadClass>? = nil) -> [Feature] {
        guard let coordinates = shape?.coordinates, let shape = shape else { return [] }
        var features: [Feature] = []
        
        for (index, leg) in legs.enumerated() {
            let legFeatures: [Feature]
            let currentLegAttribute = (legIndex != nil) ? index == legIndex : true

            if let congestionLevels = leg.resolvedCongestionLevels, congestionLevels.count < coordinates.count + 2 {
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
                    var feature = Feature(geometry: .lineString(LineString(congestionSegment.0)))
                    feature.properties = [
                        CongestionAttribute: .string(congestionSegment.1.rawValue),
                        CurrentLegAttribute: .boolean(currentLegAttribute),
                    ]
                    
                    return feature
                }
            } else {
                var feature = Feature(geometry: .lineString(LineString(shape.coordinates)))
                feature.properties = [
                    CurrentLegAttribute: .boolean(currentLegAttribute),
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
        case .restrictedRouteAreaSource:
            return "\(identifier).restricted_area_source"
        case .restrictedRouteAreaRoute:
            return "\(identifier).restricted_area_route_line"
        }
    }
    
    func leg(containing step: RouteStep) -> RouteLeg? {
        return legs.first { $0.steps.contains(step) }
    }

    var tollIntersections: [Intersection]? {
        let allSteps = legs.flatMap { return $0.steps }

        let allIntersections = allSteps.flatMap { $0.intersections ?? [] }
        let intersectionsWithTolls = allIntersections.filter { return $0.tollCollection != nil }

        return intersectionsWithTolls
    }

    // returns the list of line segments along the route that fall within given bounding box. Returns nil if there are none. Line segments are defined by the route shape coordinates that lay within the bounding box
    func shapes(within: Turf.BoundingBox) -> [LineString]? {
        guard let coordinates = shape?.coordinates else { return nil }
        var lines = [[CLLocationCoordinate2D]]()
        var currentLine: [CLLocationCoordinate2D]?
        for coordinate in coordinates {
            // see if this coordinate lays within the bounds
            if within.contains(coordinate) {
                // if there is no current line segment then start one
                if currentLine == nil {
                    currentLine = [CLLocationCoordinate2D]()
                }

                // append the coordinate to the current line segment
                currentLine?.append(coordinate)
            } else {
                // if there is a current line segment being built then finish it off and reset
                if let currentLine = currentLine {
                    lines.append(currentLine)
                }
                currentLine = nil
            }
        }

        // append any outstanding final segment
        if let currentLine = currentLine {
            lines.append(currentLine)
        }
        currentLine = nil

        // return the segments as LineStrings
        return lines.compactMap { coordinateList -> LineString? in
            return LineString(coordinateList)
        }
    }
    
    /**
     Returns true if both the legIndex and stepIndex are valid in the route.
     */
    func containsStep(at legIndex: Int, stepIndex: Int) -> Bool {
        return legs[safe: legIndex]?.steps.indices.contains(stepIndex) ?? false
    }
}

extension RouteStep {
    func intersects(_ boundingBox: Turf.BoundingBox) -> Bool {
        return shape?.coordinates.contains(where: { boundingBox.contains($0) }) ?? false
    }
}
