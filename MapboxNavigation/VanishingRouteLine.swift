import MapboxDirections
import MapboxCoreNavigation
import Turf

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
        
        guard let mainRouteLayer = style?.layer(withIdentifier: mainRouteLayerIdentifier) as? MGLLineStyleLayer,
              let mainRouteCasingLayer = style?.layer(withIdentifier: mainRouteCasingLayerIdentifier) as? MGLLineStyleLayer else { return }
        
        if fractionTraveled >= 1.0 {
            // In case if route was fully travelled - remove main route and its casing.
            style?.remove([mainRouteLayer, mainRouteCasingLayer])
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
            let mainCasingLayerStops = self.routeCasingGradient(newFractionTraveled)
            
            mainRouteLayer.lineGradient = mainRouteLayerGradient
            mainRouteCasingLayer.lineGradient = mainCasingLayerStops
        })
    }
    
    func routeLineGradient(_ route: Route, fractionTraveled: Double) -> NSExpression? {
        var gradientStops = [CGFloat: UIColor]()
        
        // In case if mainRouteLayer was already added - extract congestion segments out of it.
        if let identifier = identifier(routes?.first, identifierType: .route),
           let mainRouteLayer = style?.layer(withIdentifier: identifier) as? MGLLineStyleLayer,
           // lineGradient contains 4 arguments, last one (stops) allows to store line gradient stops, if they're present - reuse them.
           let lineGradients = mainRouteLayer.lineGradient?.arguments?[3],
           let stops = lineGradients.expressionValue(with: nil, context: nil) as? NSDictionary {
            
            for (key, value) in stops {
                if let key = key as? CGFloat, let value = (value as? NSExpression)?.expressionValue(with: nil, context: nil) as? UIColor {
                    gradientStops[key] = value
                }
            }
        } else {
            /**
             We will keep track of this value as we iterate through
             the various congestion segments.
             */
            var distanceTraveled = fractionTraveled

            /**
             Begin by calculating individual congestion segments associated
             with a congestion level, represented as `MGLPolylineFeature`s.
             */
            guard let congestionSegments = addCongestion(to: route, legIndex: 0) else { return nil }

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
            for (index, line) in congestionSegments.enumerated() {
                line.getCoordinates(line.coordinates, range: NSMakeRange(0, Int(line.pointCount)))
                // `UnsafeMutablePointer` is needed here to get the line’s coordinates.
                let buffPtr = UnsafeMutableBufferPointer(start: line.coordinates, count: Int(line.pointCount))
                let lineCoordinates = Array(buffPtr)

                // Get congestion color for the stop.
                let congestionLevel = line.attributes["congestion"] as? String
                let associatedCongestionColor = congestionColor(for: congestionLevel)

                // Measure the line length of the traffic segment.
                let lineString = LineString(lineCoordinates)
                guard let distance = lineString.distance() else { return nil }

                /**
                 If this is the first congestion segment, then the starting
                 percentage point will be zero.
                 */
                if index == congestionSegments.startIndex {
                    distanceTraveled = distanceTraveled + distance

                    let segmentEndPercentTraveled = CGFloat((distanceTraveled / route.distance))
                    gradientStops[segmentEndPercentTraveled.nextDown] = associatedCongestionColor
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
                let segmentStartPercentTraveled = CGFloat((distanceTraveled / route.distance))
                gradientStops[segmentStartPercentTraveled.nextUp] = associatedCongestionColor

                distanceTraveled = distanceTraveled + distance

                let segmentEndPercentTraveled = CGFloat((distanceTraveled / route.distance))
                gradientStops[segmentEndPercentTraveled.nextDown] = associatedCongestionColor
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
        
        // It's not possible to create line gradient in case if there are no route gradient stops.
        if !filteredGradientStops.isEmpty {
            // Dictionary usage is causing crashes in Release mode (when built with optimization SWIFT_OPTIMIZATION_LEVEL = -O flag).
            // Even though Dictionary contains valid objects prior to passing it to NSExpression:
            // [0.4109119609930762: UIExtendedSRGBColorSpace 0.952941 0.65098 0.309804 1,
            // 0.4109119609930761: UIExtendedSRGBColorSpace 0.337255 0.658824 0.984314 1]
            // keys become nil in NSExpression arguments list:
            // [0.4109119609930762 = nil,
            // 0.4109119609930761 = nil]
            // Passing NSDictionary with all data from original Dictionary to NSExpression fixes issue.
            return NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($lineProgress, 'linear', nil, %@)", NSDictionary(dictionary: filteredGradientStops))
        }
        return nil
    }
    
    func routeCasingGradient(_ fractionTraveled: Double) -> NSExpression {
        let percentTraveled = CGFloat(fractionTraveled)
        var gradientStops = [CGFloat: UIColor]()
        gradientStops[0.0] = traversedRouteColor
        gradientStops[percentTraveled.nextDown] = traversedRouteColor
        gradientStops[percentTraveled] = routeCasingColor
        
        return NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($lineProgress, 'linear', nil, %@)", NSDictionary(dictionary: gradientStops))
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
    
}
