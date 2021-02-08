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
            distance += calculateDistance(coordinate1: curr, coordinate2: prev)
            indexArray[index - 1] = RouteLineDistancesIndex(point: prev, distanceRemaining: distance)
        }
        indexArray[coordinates.count - 1] = RouteLineDistancesIndex(point: coordinates[coordinates.count - 1], distanceRemaining: 0.0)
        return RouteLineGranularDistances(distance: distance, distanceArray: indexArray.compactMap{ $0 })
    }
    
    /**
     Calculates the distance between 2 points using [EPSG:3857 projection](https://epsg.io/3857).
     */
    func calculateDistance(coordinate1: CLLocationCoordinate2D, coordinate2: CLLocationCoordinate2D) -> Double {
        let distanceArray: [Double] = [
            (projectX(coordinate1.longitude) - projectX(coordinate2.longitude)),
            (projectY(coordinate1.latitude) - projectY(coordinate2.latitude))
        ]
        return (distanceArray[0] * distanceArray[0] + distanceArray[1] * distanceArray[1]).squareRoot()
    }

    func projectX(_ x: Double) -> Double {
        return x / 360.0 + 0.5
    }
    
    func projectY(_ y: Double) -> Double {
        let sinValue = sin(y * Double.pi / 180)
        let newYValue = 0.5 - 0.25 * log((1 + sinValue) / (1 - sinValue)) / Double.pi
        if newYValue < 0 {
            return 0.0
        } else if newYValue > 1 {
            return 1.1
        } else {
            return newYValue
        }
    }
    
    /**
     Updates the route line appearance from the origin point to the indicated point
     - parameter coordinate: current position of the puck
     */
    func updateTraveledRouteLine(_ coordinate: CLLocationCoordinate2D?) {
        guard let granularDistances = routeLineGranularDistances,let index = routeRemainingDistancesIndex, let location = coordinate else { return }
        let traveledIndex = granularDistances.distanceArray[index]
        let upcomingPoint = traveledIndex.point
        
        /**
         Take the remaining distance from the upcoming point on the route and extends it by the exact position of the puck.
         */
        let remainingDistance = traveledIndex.distanceRemaining + calculateDistance(coordinate1: upcomingPoint, coordinate2: location)
        
        /**
         Calculate the percentage of the route traveled.
         */
        if granularDistances.distance >= remainingDistance {
            let offSet = (1.0 - remainingDistance / granularDistances.distance)
            if offSet >= 0 {
                preFractionTraveled = fractionTraveled
                fractionTraveled = offSet
            }
        }
    }
    
    /**
     Updates the route style layer and its casing style layer to gradually disappear as the user location puck travels along the displayed route.
     
     - parameter routeProgress: Current route progress.
     */
    public func updateRoute(_ routeProgress: RouteProgress) {
        guard let mainRouteLayerIdentifier = identifier(routes?.first, identifierType: .route),
              let mainRouteCasingLayerIdentifier = identifier(routes?.first, identifierType: .routeCasing) else { return }
        
        if fractionTraveled >= 1.0 {
            // In case if route was fully travelled - remove main route and its casing.
            
            let _ = mapView.style.removeStyleLayer(forLayerId: mainRouteLayerIdentifier)
            let _ = mapView.style.removeStyleLayer(forLayerId: mainRouteCasingLayerIdentifier)

            fractionTraveled = 0.0
            preFractionTraveled = 0.0
            return
        }
        
        vanishingRouteLineUpdateTimer?.invalidate()
        vanishingRouteLineUpdateTimer = nil
        
        let traveledDifference = fractionTraveled - preFractionTraveled
        if traveledDifference == 0.0 {
            return
        }
        let startDate = Date()
        vanishingRouteLineUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true, block: { timer in
            let timePassedInMilliseconds = Date().timeIntervalSince(startDate) * 1000
            if timePassedInMilliseconds >= 980 {
                timer.invalidate()
                return
            }
            let newFractionTraveled = self.preFractionTraveled + traveledDifference * timePassedInMilliseconds.truncatingRemainder(dividingBy: 1000) / 1000
            guard let mainRouteLayerGradient = self.routeLineGradient(routeProgress.route, fractionTraveled: newFractionTraveled) else { return }
            let mainRouteCasingLayerGradient = self.routeCasingGradient(newFractionTraveled)
            
            guard var mainRouteLineLayer = try? self.mapView.style.getLayer(with: mainRouteLayerIdentifier, type: LineLayer.self).get(),
                  var mainRouteLineCasingLayer = try? self.mapView.style.getLayer(with: mainRouteCasingLayerIdentifier, type: LineLayer.self).get() else { return }
            
            mainRouteLineLayer.paint?.lineGradient = .expression(Expression.routeLineGradientExpression(mainRouteLayerGradient))
            mainRouteLineCasingLayer.paint?.lineGradient = .expression(Expression.routeLineGradientExpression(mainRouteCasingLayerGradient))
        })
    }
    
    func routeLineGradient(_ route: Route, fractionTraveled: Double) -> [Double: UIColor]? {
        var gradientStops = [CGFloat: UIColor]()
        
        /**
         We will keep track of this value as we iterate through
         the various congestion segments.
         */
        var distanceTraveled = fractionTraveled
        
        /**
         Begin by calculating individual congestion segments associated
         with a congestion level.
         */
        let congestionSegments = addCongestion(to: route, legIndex: 0)
        
        /**
         To create the stops dictionary that represents the route line expressed
         as gradients, for every congestion segment we need one pair of dictionary
         entries to represent the color to be displayed between that range. Depending
         on the index of the congestion segment, the pair's first or second key
         will have a buffer value added or subtracted to make room for a gradient
         transition between congestion segments.
         
         green       gradient       red
         transition
         |-----------|~~~~~~~~~~~~|----------|
         0         0.499        0.501       1.0
         */
        
        for (index, feature) in congestionSegments.enumerated() {
            // Get congestion color for the stop.
            
            let congestionLevel = feature.properties?[CongestionAttribute] as? String
            let associatedCongestionColor = congestionColor(for: congestionLevel)
            
            // Measure the line length of the traffic segment.
            let lineString = feature.geometry.value as? LineString
            guard let distance = lineString?.distance() else { return nil }
            
            /**
             If this is the first congestion segment, then the starting
             percentage point will be zero.
             */
            if index == congestionSegments.startIndex {
                distanceTraveled = distanceTraveled + distance

                let segmentEndPercentTraveled = CGFloat(distanceTraveled / route.distance)
                gradientStops[segmentEndPercentTraveled.nextDown] = associatedCongestionColor
                
                if index + 1 < congestionSegments.count {
                    gradientStops[segmentEndPercentTraveled.nextUp] = congestionColor(for: congestionSegments[index + 1].properties?["congestion"] as? String)
                }
                
                continue
            }
            
            /**
             If this is the last congestion segment, then the ending
             percentage point will be 1.0, to represent 100%.
             */
            if index == congestionSegments.endIndex - 1 {
                let segmentEndPercentTraveled = CGFloat(1.0)
                gradientStops[segmentEndPercentTraveled.nextDown] = associatedCongestionColor
                continue
            }
            
            /**
             If this is not the first or last congestion segment, then
             the starting and ending percent values traveled for this segment
             will be a fractional amount more/less than the actual values.
             */
            let segmentStartPercentTraveled = CGFloat(distanceTraveled / route.distance)
            gradientStops[segmentStartPercentTraveled.nextUp] = associatedCongestionColor
            
            distanceTraveled = distanceTraveled + distance
            
            let segmentEndPercentTraveled = CGFloat(distanceTraveled / route.distance)
            gradientStops[segmentEndPercentTraveled.nextDown] = associatedCongestionColor
            
            if index + 1 < congestionSegments.count {
                gradientStops[segmentEndPercentTraveled.nextUp] = congestionColor(for: congestionSegments[index + 1].properties?["congestion"] as? String)
            }
        }
        
        let percentTraveled = CGFloat(fractionTraveled)
        
        // Filter out only the stops that are greater than or equal to the percent of the route traveled.
        var filteredGradientStops = gradientStops.filter { key, value in
            return key >= percentTraveled
        }
        
        // Then, get the lowest value from the above and fade the range from zero that lowest value,
        // which represents the % of the route traveled.
        if let minStop = filteredGradientStops.min(by: { $0.0 < $1.0 }) {
            filteredGradientStops[0.0] = traversedRouteColor
            filteredGradientStops[percentTraveled.nextDown] = traversedRouteColor
            filteredGradientStops[percentTraveled] = minStop.value
        }
        
        var resultGradientStops = [Double: UIColor]()

        filteredGradientStops.filter({ $0.0 >= 0.0 }).forEach {
            resultGradientStops[Double($0.0).round(16)] = $0.1
        }
        
        return resultGradientStops
    }
    
    func routeCasingGradient(_ fractionTraveled: Double) -> [Double: UIColor] {
        let percentTraveled = CGFloat(fractionTraveled)
        var gradientStops = [CGFloat: UIColor]()
        gradientStops[0.0] = traversedRouteColor
        gradientStops[percentTraveled.nextDown] = traversedRouteColor
        gradientStops[percentTraveled != 0.0 ? percentTraveled : 1.0] = routeCasingColor
        
        var resultGradientStops = [Double: UIColor]()
        gradientStops.filter({ $0.0 >= 0.0 }).forEach {
            resultGradientStops[Double($0.0)] = $0.1
        }
        
        return resultGradientStops
    }
    
    /**
     Given a congestion level, return its associated color.
     */
    func congestionColor(for congestionLevel: String?) -> UIColor {
        switch congestionLevel {
        case "low":
            return trafficLowColor
        case "moderate":
            return trafficModerateColor
        case "heavy":
            return trafficHeavyColor
        case "severe":
            return trafficSevereColor
        default:
            return trafficUnknownColor
        }
    }
    
    func addCongestion(to route: Route, legIndex: Int?) -> [Feature] {
        guard let coordinates = route.shape?.coordinates, let shape = route.shape else { return [] }
        
        var features: [Feature] = []
        
        for (index, leg) in route.legs.enumerated() {
            let legFeatures: [Feature]
            
            if let legCongestion = leg.segmentCongestionLevels, legCongestion.count < coordinates.count {
                // The last coord of the preceding step, is shared with the first coord of the next step, we don't need both.
                let legCoordinates: [CLLocationCoordinate2D] = leg.steps.enumerated().reduce([]) { allCoordinates, current in
                    let index = current.offset
                    let step = current.element
                    let stepCoordinates = step.shape!.coordinates
                    
                    return index == 0 ? stepCoordinates : allCoordinates + stepCoordinates.suffix(from: 1)
                }
                
                let mergedCongestionSegments = combine(legCoordinates,
                                                       with: legCongestion,
                                                       streetsRoadClasses: leg.streetsRoadClasses,
                                                       roadClassesWithOverriddenCongestionLevels: roadClassesWithOverriddenCongestionLevels)
                
                legFeatures = mergedCongestionSegments.map { (congestionSegment: CongestionSegment) -> Feature in
                    var feature = Feature(LineString(congestionSegment.0))
                    feature.properties = [
                        CongestionAttribute: String(describing: congestionSegment.1),
                        "isAlternateRoute": false,
                        CurrentLegAttribute: (legIndex != nil) ? index == legIndex : index == 0
                    ]
                    
                    return feature
                }
            } else {
                var feature = Feature(LineString(shape.coordinates))
                feature.properties = [
                    "isAlternateRoute": false,
                    CurrentLegAttribute: (legIndex != nil) ? index == legIndex : index == 0
                ]
                legFeatures = [feature]
            }
            
            features.append(contentsOf: legFeatures)
        }
        
        return features
    }
    
    /**
     Returns an array of congestion segments by associating the given congestion levels with the coordinates of the respective line segments that they apply to.
     
     This method coalesces consecutive line segments that have the same congestion level.
     
     For each item in the`CongestionSegment` collection a `CongestionLevel` substitution will take place that has a streets road class contained in the `roadClassesWithOverriddenCongestionLevels` collection.
     For each of these items the `CongestionLevel` for `.unknown` traffic congestion will be replaced with the `.low` traffic congestion.
     
     - parameter coordinates: The coordinates of a leg.
     - parameter congestions: The congestion levels along a leg. There should be one fewer congestion levels than coordinates.
     - parameter streetsRoadClasses: A collection of streets road classes for each geometry index in `Intersection`. There should be the same amount of `streetsRoadClasses` and `congestions`.
     - parameter roadClassesWithOverriddenCongestionLevels: Streets road classes for which a `CongestionLevel` substitution should occur.
     - returns: A list of `CongestionSegment` tuples with coordinate and congestion level.
     */
    func combine(_ coordinates: [CLLocationCoordinate2D],
                 with congestions: [CongestionLevel],
                 streetsRoadClasses: [MapboxStreetsRoadClass?]? = nil,
                 roadClassesWithOverriddenCongestionLevels: Set<MapboxStreetsRoadClass>? = nil) -> [CongestionSegment] {
        var segments: [CongestionSegment] = []
        segments.reserveCapacity(congestions.count)
        
        var index = 0
        for (firstSegment, congestionLevel) in zip(zip(coordinates, coordinates.suffix(from: 1)), congestions) {
            let coordinates = [firstSegment.0, firstSegment.1]
            
            var overriddenCongestionLevel = congestionLevel
            if let streetsRoadClasses = streetsRoadClasses,
               let roadClassesWithOverriddenCongestionLevels = roadClassesWithOverriddenCongestionLevels,
               streetsRoadClasses.indices.contains(index),
               let streetsRoadClass = streetsRoadClasses[index],
               congestionLevel == .unknown,
               roadClassesWithOverriddenCongestionLevels.contains(streetsRoadClass) {
                overriddenCongestionLevel = .low
            }
            
            if segments.last?.1 == overriddenCongestionLevel {
                segments[segments.count - 1].0 += coordinates
            } else {
                segments.append((coordinates, overriddenCongestionLevel))
            }
            
            index += 1
        }
        
        return segments
    }
}
