import CoreLocation
import UIKit
import MapboxDirections
import MapboxCoreNavigation
import Turf
import MapboxMaps

extension NavigationMapView {

    struct RoutePoints {
        var nestedList: [[[CLLocationCoordinate2D]]]
        var flatList: [CLLocationCoordinate2D]
    }
    
    struct RouteLineGranularDistances {
        var distance: Double
        var distanceArray: [RouteLineDistancesIndex]
    }
    
    struct RouteLineDistancesIndex {
        var point: CLLocationCoordinate2D
        var distanceRemaining: Double
    }
    
    // MARK: - Vanishing route line methods
    
    func initPrimaryRoutePoints(route: Route) {
        routePoints = parseRoutePoints(route: route)
        routeLineGranularDistances = calculateGranularDistances(routePoints?.flatList ?? [])
    }
    
    /**
     Tranform the route data into nested arrays of legs -> steps -> coordinates.
     The first and last point of adjacent steps overlap and are duplicated.
     */
    func parseRoutePoints(route: Route) -> RoutePoints {
        let nestedList = route.legs.map { (routeLeg: RouteLeg) -> [[CLLocationCoordinate2D]] in
            return routeLeg.steps.map { (routeStep: RouteStep) -> [CLLocationCoordinate2D] in
                if let routeShape = routeStep.shape {
                    if !routeShape.coordinates.isEmpty {
                        return routeShape.coordinates
                    } else { return [] }
                } else {
                    return []
                }
            }
        }
        let flatList = nestedList.flatMap { $0.flatMap { $0.compactMap { $0 } } }
        return RoutePoints(nestedList: nestedList, flatList: flatList)
    }
    
    /**
     Find and cache the index of the upcoming [RouteLineDistancesIndex].
     */
    public func updateUpcomingRoutePointIndex(routeProgress: RouteProgress) {
        guard let completeRoutePoints = routePoints else {
            routeRemainingDistancesIndex = nil
            return
        }
        let currentLegProgress = routeProgress.currentLegProgress
        let currentStepProgress = routeProgress.currentLegProgress.currentStepProgress
        /**
         Find the count of remaining points in the current step.
         */
        var allRemainingPoints = getSlicedLinePointsCount(currentLegProgress: currentLegProgress, currentStepProgress: currentStepProgress)
        
        /**
         Add to the count of remaining points all of the remaining points on the current leg, after the current step.
         */
        let currentLegSteps = completeRoutePoints.nestedList[routeProgress.legIndex]
        let startIndex = currentLegProgress.stepIndex + 1
        let endIndex = currentLegSteps.count - 1
        if startIndex < endIndex {
            allRemainingPoints += currentLegSteps.prefix(endIndex).suffix(from: startIndex).flatMap{ $0.compactMap{ $0 } }.count
        }
        
        /**
         Add to the count of remaining points all of the remaining legs.
         */
        for index in stride(from: routeProgress.legIndex + 1, to: completeRoutePoints.nestedList.count, by: 1) {
            allRemainingPoints += completeRoutePoints.nestedList[index].flatMap{ $0 }.count
        }
        
        /**
         After calculating the number of remaining points and the number of all points,  calculate the index of the upcoming point.
         */
        let allPoints = completeRoutePoints.flatList.count
        routeRemainingDistancesIndex = allPoints - allRemainingPoints - 1
    }
    
    func getSlicedLinePointsCount(currentLegProgress: RouteLegProgress, currentStepProgress: RouteStepProgress) -> Int {
        let startDistance = currentStepProgress.distanceTraveled
        let stopDistance = currentStepProgress.step.distance
        
        /**
         Implement the Turf.lineSliceAlong(lineString, startDistance, stopDistance) to return a sliced lineString.
         */
        if let lineString = currentStepProgress.step.shape,
           let midPoint = lineString.coordinateFromStart(distance: startDistance),
           let slicedLine = lineString.trimmed(from: midPoint, distance: stopDistance - startDistance) {
            return slicedLine.coordinates.count - 1
        }
         
        return 0
    }
    
    func calculateGranularDistances(_ coordinates: [CLLocationCoordinate2D]) -> RouteLineGranularDistances? {
        if coordinates.isEmpty { return nil }
        var distance = 0.0
        var indexArray = [RouteLineDistancesIndex?](repeating: nil, count: coordinates.count)
        for index in stride(from: coordinates.count - 1, to: 0, by: -1) {
            let curr = coordinates[index]
            let prev = coordinates[index - 1]
            distance += curr.projectedDistance(to: prev)
            indexArray[index - 1] = RouteLineDistancesIndex(point: prev, distanceRemaining: distance)
        }
        indexArray[coordinates.count - 1] = RouteLineDistancesIndex(point: coordinates[coordinates.count - 1], distanceRemaining: 0.0)
        return RouteLineGranularDistances(distance: distance, distanceArray: indexArray.compactMap{ $0 })
    }
    
    /**
     Updates the fractionTraveled along the route line from the origin point to the indicated point.
     
     - parameter coordinate: Current position of the user location.
     */
    func updateFractionTraveled(coordinate: CLLocationCoordinate2D) {
        guard let granularDistances = routeLineGranularDistances,let index = routeRemainingDistancesIndex else { return }
        guard index < granularDistances.distanceArray.endIndex else { return }
        let traveledIndex = granularDistances.distanceArray[index]
        let upcomingPoint = traveledIndex.point
        
        /**
         Take the remaining distance from the upcoming point on the route and extends it by the exact position of the puck.
         */
        let remainingDistance = traveledIndex.distanceRemaining + upcomingPoint.projectedDistance(to: coordinate)
        
        /**
         Calculate the percentage of the route traveled.
         */
        if granularDistances.distance >= remainingDistance {
            let offSet = (1.0 - remainingDistance / granularDistances.distance)
            if offSet >= 0 {
                fractionTraveled = offSet
            }
        }
    }
    
    /**
     Updates the route style layer and its casing style layer to gradually disappear as the user location puck travels along the displayed route.
     
     - parameter coordinate: Current position of the user location.
     */
    public func travelAlongRouteLine(to coordinate: CLLocationCoordinate2D?) {
        guard let route = routes?.first else { return }
        
        guard pendingCoordinateForRouteLine != coordinate,
              let preCoordinate = pendingCoordinateForRouteLine,
              let currentCoordinate = coordinate else { return }
        
        let distance = preCoordinate.distance(to: currentCoordinate)
        let meterPerPixel = getMetersPerPixelAtLatitude(currentCoordinate.latitude, Double(mapView.cameraState.zoom))
        guard distance >= meterPerPixel else { return }
            
        updateFractionTraveled(coordinate: currentCoordinate)
        
        let mainRouteLayerIdentifier = route.identifier(.route(isMainRoute: true))
        let mainRouteCasingLayerIdentifier = route.identifier(.routeCasing(isMainRoute: true))
        
        if fractionTraveled >= 1.0 {
            // In case if route was fully travelled - remove main route and its casing.
            do {
                try mapView.mapboxMap.style.removeLayer(withId: mainRouteLayerIdentifier)
                try mapView.mapboxMap.style.removeLayer(withId: mainRouteCasingLayerIdentifier)
            } catch {
                print("Failed to remove main route line layer.")
            }
            
            fractionTraveled = 0.0
            return
        }
        
        do {
            try mapView.mapboxMap.style.updateLayer(withId: mainRouteLayerIdentifier) { (lineLayer: inout LineLayer) throws in
                let mainRouteLayerGradient = self.updateRouteLineGradientStops(fractionTraveled: fractionTraveled, gradientStops: currentLineGradientStops)
                lineLayer.lineGradient = .expression(Expression.routeLineGradientExpression(mainRouteLayerGradient, lineBaseColor: trafficUnknownColor))
            }
            
            try mapView.mapboxMap.style.updateLayer(withId: mainRouteCasingLayerIdentifier) { (lineLayer: inout LineLayer) throws in
                let mainRouteCasingLayerGradient = routeLineGradient(fractionTraveled: fractionTraveled)
                lineLayer.lineGradient = .expression(Expression.routeLineGradientExpression(mainRouteCasingLayerGradient, lineBaseColor: routeCasingColor))
            }
        } catch {
            print("Failed to update main route line layer.")
        }
        
        pendingCoordinateForRouteLine = coordinate
    }
    
    func updateRouteLineGradientStops(fractionTraveled: Double, gradientStops: [Double: UIColor]) -> [Double: UIColor] {
        var filteredGradientStops = gradientStops.filter { key, value in
            return key >= fractionTraveled
        }
        filteredGradientStops[0.0] = traversedRouteColor
        
        let  nextDownFractionTraveled = Double(CGFloat(fractionTraveled).nextDown)
        if nextDownFractionTraveled >= 0.0 {
            filteredGradientStops[nextDownFractionTraveled] = traversedRouteColor
        }
        
        // Find the nearest smaller stop than the `fractionTraveled` and apply its color to the `fractionTraveled` till the next stop.
        let sortedStops = gradientStops.keys.sorted()
        if let minStop = sortedStops.last(where: { $0 <= fractionTraveled }),
           minStop != 0.0 {
            filteredGradientStops[fractionTraveled] = gradientStops[minStop]
        } else {
            filteredGradientStops[fractionTraveled] = trafficUnknownColor
        }

        return filteredGradientStops
    }
    
    func routeLineGradient(_ congestionFeatures: [Turf.Feature]? = nil, fractionTraveled: Double, isMain: Bool = true) -> [Double: UIColor] {
        var gradientStops = [Double: UIColor]()
        var distanceTraveled = fractionTraveled
        
        if let congestionFeatures = congestionFeatures {
            let routeDistance = congestionFeatures.compactMap({ ($0.geometry.value as? LineString)?.distance() }).reduce(0, +)
            var minimumSegment: (Double, UIColor) = (Double.greatestFiniteMagnitude, .clear)
            
            for (index, feature) in congestionFeatures.enumerated() {
                var associatedFeatureColor = routeCasingColor
                let congestionLevel = feature.properties?[CongestionAttribute] as? String
                if let isCurrentLeg = feature.properties?[CurrentLegAttribute] as? Bool, isCurrentLeg {
                    associatedFeatureColor = congestionColor(for: congestionLevel, isMain: isMain)
                }

                let lineString = feature.geometry.value as? LineString
                guard let distance = lineString?.distance() else { return gradientStops }
                
                if index == congestionFeatures.startIndex {
                    distanceTraveled = distanceTraveled + distance
                    
                    let segmentEndPercentTraveled = CGFloat(distanceTraveled / routeDistance)
                    let currentGradientStop = Double(segmentEndPercentTraveled.nextDown)
                    if currentGradientStop >= fractionTraveled {
                        gradientStops[currentGradientStop] = associatedFeatureColor
                        
                        if currentGradientStop < minimumSegment.0 {
                            minimumSegment = (currentGradientStop, associatedFeatureColor)
                        }
                        
                        if index + 1 < congestionFeatures.count {
                            let currentGradientStop = Double(segmentEndPercentTraveled.nextUp)
                            let currentColor = congestionColor(for: congestionFeatures[index + 1].properties?["congestion"] as? String, isMain: isMain)
                            gradientStops[currentGradientStop] = currentColor
                            
                            if currentGradientStop < minimumSegment.0 {
                                minimumSegment = (currentGradientStop, currentColor)
                            }
                        }
                    }
                    
                    continue
                }
                
                if index == congestionFeatures.endIndex - 1 {
                    let lastGradientStop: Double = 1.0
                    gradientStops[lastGradientStop] = associatedFeatureColor
                    
                    if lastGradientStop < minimumSegment.0 {
                        minimumSegment = (lastGradientStop, associatedFeatureColor)
                    }
                    
                    continue
                }
                
                let segmentStartPercentTraveled = CGFloat(distanceTraveled / routeDistance)
                
                if Double(segmentStartPercentTraveled.nextUp) >= fractionTraveled {
                    let currentGradientStop = Double(segmentStartPercentTraveled.nextUp)
                    gradientStops[currentGradientStop] = associatedFeatureColor
                    
                    if currentGradientStop < minimumSegment.0 {
                        minimumSegment = (currentGradientStop, associatedFeatureColor)
                    }
                }
                
                distanceTraveled = distanceTraveled + distance
                
                let segmentEndPercentTraveled = CGFloat(distanceTraveled / routeDistance)
                if Double(segmentEndPercentTraveled.nextDown) >= fractionTraveled {
                    let currentGradientStop = Double(segmentEndPercentTraveled.nextDown)
                    gradientStops[currentGradientStop] = associatedFeatureColor
                    
                    if currentGradientStop < minimumSegment.0 {
                        minimumSegment = (currentGradientStop, associatedFeatureColor)
                    }
                }

                if index + 1 < congestionFeatures.count && Double(segmentEndPercentTraveled.nextUp) >= fractionTraveled {
                    let currentGradientStop = Double(segmentEndPercentTraveled.nextUp)
                    let nextCongestionLevel = congestionFeatures[index + 1].properties?[CongestionAttribute] as? String
                    var currentColor = routeCasingColor
                    if let isCurrentLeg = congestionFeatures[index + 1].properties?[CurrentLegAttribute] as? Bool, isCurrentLeg {
                        currentColor = congestionColor(for: nextCongestionLevel, isMain: isMain)
                    }
                    gradientStops[currentGradientStop] = currentColor
                    
                    if currentGradientStop < minimumSegment.0 {
                        minimumSegment = (currentGradientStop, currentColor)
                    }
                }
            }
            
            gradientStops[0.0] = traversedRouteColor
            let currentGradientStop = Double(CGFloat(fractionTraveled).nextDown)
            if currentGradientStop >= 0.0 {
                gradientStops[currentGradientStop] = traversedRouteColor
            }
            gradientStops[fractionTraveled] = minimumSegment.1
        } else {
            let percentTraveled = CGFloat(fractionTraveled)
            gradientStops[0.0] = traversedRouteColor
            if percentTraveled.nextDown >= 0.0 {
                gradientStops[Double(percentTraveled.nextDown)] = traversedRouteColor
            }
            gradientStops[Double(percentTraveled)] = routeCasingColor
        }
        
        return gradientStops
    }
    
    /**
     Given a congestion level, return its associated color.
     */
    func congestionColor(for congestionLevel: String?, isMain: Bool) -> UIColor {
        switch congestionLevel {
        case "low":
            return isMain ? trafficLowColor : alternativeTrafficLowColor
        case "moderate":
            return isMain ? trafficModerateColor : alternativeTrafficModerateColor
        case "heavy":
            return isMain ? trafficHeavyColor : alternativeTrafficHeavyColor
        case "severe":
            return isMain ? trafficSevereColor : alternativeTrafficSevereColor
        default:
            return isMain ? trafficUnknownColor : alternativeTrafficUnknownColor
        }
    }
}
