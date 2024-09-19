import _MapboxNavigationHelpers
import CoreLocation
import MapboxDirections
import MapboxMaps
import UIKit

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

    // MARK: Customizing and Displaying the Route Line(s)

    func initPrimaryRoutePoints(route: Route) {
        routePoints = parseRoutePoints(route: route)
        routeLineGranularDistances = calculateGranularDistances(routePoints?.flatList ?? [])
    }

    /// Transform the route data into nested arrays of legs -> steps -> coordinates.
    /// The first and last point of adjacent steps overlap and are duplicated.
    func parseRoutePoints(route: Route) -> RoutePoints {
        let nestedList = route.legs.map { (routeLeg: RouteLeg) -> [[CLLocationCoordinate2D]] in
            return routeLeg.steps.map { (routeStep: RouteStep) -> [CLLocationCoordinate2D] in
                if let routeShape = routeStep.shape {
                    return routeShape.coordinates
                } else {
                    return []
                }
            }
        }
        let flatList = nestedList.flatMap { $0.flatMap { $0.compactMap { $0 } } }
        return RoutePoints(nestedList: nestedList, flatList: flatList)
    }

    func updateRouteLine(routeProgress: RouteProgress) {
        updateIntersectionAnnotations(routeProgress: routeProgress)
        if let routes {
            mapStyleManager.updateRouteAlertsAnnotations(
                navigationRoutes: routes,
                excludedRouteAlertTypes: excludedRouteAlertTypes,
                distanceTraveled: routeProgress.distanceTraveled
            )
        }

        if routeLineTracksTraversal, routes != nil {
            guard !routeProgress.routeIsComplete else {
                mapStyleManager.removeRoutes()
                mapStyleManager.removeArrows()
                return
            }

            updateUpcomingRoutePointIndex(routeProgress: routeProgress)
        }
        updateArrow(routeProgress: routeProgress)
    }

    func updateAlternatives(routeProgress: RouteProgress?) {
        guard let routes = routeProgress?.navigationRoutes ?? routes else { return }
        show(routes, routeAnnotationKinds: routeAnnotationKinds)
    }

    func updateIntersectionAnnotations(routeProgress: RouteProgress?) {
        if let routeProgress, showsIntersectionAnnotations {
            mapStyleManager.updateIntersectionAnnotations(routeProgress: routeProgress)
        } else {
            mapStyleManager.removeIntersectionAnnotations()
        }
    }

    /// Find and cache the index of the upcoming [RouteLineDistancesIndex].
    func updateUpcomingRoutePointIndex(routeProgress: RouteProgress) {
        guard let completeRoutePoints = routePoints,
              completeRoutePoints.nestedList.indices.contains(routeProgress.legIndex)
        else {
            routeRemainingDistancesIndex = nil
            return
        }
        let currentLegProgress = routeProgress.currentLegProgress
        let currentStepProgress = routeProgress.currentLegProgress.currentStepProgress
        let currentLegSteps = completeRoutePoints.nestedList[routeProgress.legIndex]
        var allRemainingPoints = 0
        // Find the count of remaining points in the current step.
        let lineString = currentStepProgress.step.shape ?? LineString([])
        // If user hasn't arrived at current step. All the coordinates will be included to the remaining points.
        if currentStepProgress.distanceTraveled < 0 {
            allRemainingPoints += currentLegSteps[currentLegProgress.stepIndex].count
        } else if let startIndex = lineString
            .indexedCoordinateFromStart(distance: currentStepProgress.distanceTraveled)?.index,
            lineString.coordinates.indices.contains(startIndex)
        {
            allRemainingPoints += lineString.coordinates.suffix(from: startIndex + 1).dropLast().count
        }

        // Add to the count of remaining points all of the remaining points on the current leg, after the current step.
        if currentLegProgress.stepIndex < currentLegSteps.endIndex {
            var count = 0
            for stepIndex in (currentLegProgress.stepIndex + 1)..<currentLegSteps.endIndex {
                count += currentLegSteps[stepIndex].count
            }
            allRemainingPoints += count
        }

        // Add to the count of remaining points all of the remaining legs.
        if routeProgress.legIndex < completeRoutePoints.nestedList.endIndex {
            var count = 0
            for remainingLegIndex in (routeProgress.legIndex + 1)..<completeRoutePoints.nestedList.endIndex {
                for remainingStepIndex in completeRoutePoints.nestedList[remainingLegIndex].indices {
                    count += completeRoutePoints.nestedList[remainingLegIndex][remainingStepIndex].count
                }
            }
            allRemainingPoints += count
        }

        // After calculating the number of remaining points and the number of all points,  calculate the index of the
        // upcoming point.
        let allPoints = completeRoutePoints.flatList.count
        routeRemainingDistancesIndex = allPoints - allRemainingPoints
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
        indexArray[coordinates.count - 1] = RouteLineDistancesIndex(
            point: coordinates[coordinates.count - 1],
            distanceRemaining: 0.0
        )
        return RouteLineGranularDistances(distance: distance, distanceArray: indexArray.compactMap { $0 })
    }

    func findClosestCoordinateOnCurrentLine(
        coordinate: CLLocationCoordinate2D,
        granularDistances: RouteLineGranularDistances,
        upcomingIndex: Int
    ) -> CLLocationCoordinate2D {
        guard granularDistances.distanceArray.indices.contains(upcomingIndex) else { return coordinate }

        var coordinates = [CLLocationCoordinate2D]()

        // Takes the passed 10 points and the upcoming point of route to form a sliced polyline for distance
        // calculation, incase of the curved shape of route.
        for index in max(0, upcomingIndex - 10)...upcomingIndex {
            let point = granularDistances.distanceArray[index].point
            coordinates.append(point)
        }

        let polyline = LineString(coordinates)

        return polyline.closestCoordinate(to: coordinate)?.coordinate ?? coordinate
    }

    /// Updates the fractionTraveled along the route line from the origin point to the indicated point.
    ///
    /// - parameter coordinate: Current position of the user location.
    func calculateFractionTraveled(coordinate: CLLocationCoordinate2D) -> Double? {
        guard let granularDistances = routeLineGranularDistances,
              let index = routeRemainingDistancesIndex,
              granularDistances.distanceArray.indices.contains(index) else { return nil }
        let traveledIndex = granularDistances.distanceArray[index]
        let upcomingPoint = traveledIndex.point

        // Project coordinate onto current line to properly find offset without an issue of back-growing route line.
        let coordinate = findClosestCoordinateOnCurrentLine(
            coordinate: coordinate,
            granularDistances: granularDistances,
            upcomingIndex: index + 1
        )

        // Take the remaining distance from the upcoming point on the route and extends it by the exact position of the
        // puck.
        let remainingDistance = traveledIndex.distanceRemaining + upcomingPoint.projectedDistance(to: coordinate)

        // Calculate the percentage of the route traveled.
        if granularDistances.distance > 0 {
            let offset = (1.0 - remainingDistance / granularDistances.distance)
            if offset >= 0 {
                return offset
            } else {
                return nil
            }
        }
        return nil
    }

    /// Updates the route style layer and its casing style layer to gradually disappear as the user location puck
    /// travels along the displayed route.
    ///
    /// - parameter coordinate: Current position of the user location.
    func travelAlongRouteLine(to coordinate: CLLocationCoordinate2D?) {
        guard let coordinate, routes != nil else { return }
        if let fraction = calculateFractionTraveled(coordinate: coordinate) {
            mapStyleManager.setRouteLineOffset(fraction, for: .main)
        }
    }
}
