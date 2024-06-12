import CoreLocation
import Foundation
import MapboxDirections
import UIKit

struct ViewportParametersProvider: Sendable {
    func parameters(
        with location: CLLocation?,
        heading: CLHeading?,
        routeProgress: RouteProgress?,
        viewportPadding: UIEdgeInsets,
        options: NavigationViewportDataSourceOptions
    ) -> ViewportDataSourceState {
        if let routeProgress {
            let intersectionDensity = options.followingCameraOptions.intersectionDensity
            let stepIndex = routeProgress.currentLegProgress.stepIndex
            let nextStepIndex = min(stepIndex + 1, routeProgress.currentLeg.steps.count - 1)

            var remainingCoordinatesOnRoute = routeProgress.currentLegProgress.currentStepProgress
                .remainingStepCoordinates()
            routeProgress.currentLeg.steps[nextStepIndex...]
                .lazy
                .compactMap { $0.shape?.coordinates }
                .forEach { stepCoordinates in
                    remainingCoordinatesOnRoute.append(contentsOf: stepCoordinates)
                }

            return .init(
                location: location,
                heading: heading,
                navigationState: .active(
                    .init(
                        coordinatesToManeuver: routeProgress.currentLegProgress.currentStepProgress
                            .remainingStepCoordinates(),
                        lookaheadDistance: lookaheadDistance(routeProgress, intersectionDensity: intersectionDensity),
                        currentLegStepIndex: routeProgress.currentLegProgress.stepIndex,
                        currentLegSteps: routeProgress.currentLeg.steps,
                        isRouteComplete: routeProgress.routeIsComplete == true,
                        remainingCoordinatesOnRoute: remainingCoordinatesOnRoute,
                        transportType: routeProgress.currentLegProgress.currentStep.transportType,
                        distanceRemainingOnStep: routeProgress.currentLegProgress.currentStepProgress.distanceRemaining
                    )
                ),
                viewportPadding: viewportPadding
            )
        } else {
            return .init(
                location: location,
                navigationState: .passive,
                viewportPadding: viewportPadding
            )
        }
    }

    /// Calculates lookahead distance based on current ``RouteProgress`` and ``IntersectionDensity`` coefficients.
    /// Lookahead distance value will be influenced by both ``IntersectionDensity.minimumDistanceBetweenIntersections``
    /// and ``IntersectionDensity.averageDistanceMultiplier``.
    /// - Parameters:
    ///   - routeProgress: Current `RouteProgress`
    ///   - intersectionDensity: Lookahead distance
    /// - Returns: The lookahead distance.
    private func lookaheadDistance(
        _ routeProgress: RouteProgress,
        intersectionDensity: IntersectionDensity
    ) -> CLLocationDistance {
        let averageIntersectionDistances = routeProgress.route.legs.map { leg -> [CLLocationDistance] in
            return leg.steps.map { step -> CLLocationDistance in
                if let firstStepCoordinate = step.shape?.coordinates.first,
                   let lastStepCoordinate = step.shape?.coordinates.last
                {
                    let intersectionLocations = [firstStepCoordinate] + (
                        step.intersections?.map(\.location) ?? []
                    ) +
                        [lastStepCoordinate]
                    let intersectionDistances = intersectionLocations[1...].enumerated()
                        .map { index, intersection -> CLLocationDistance in
                            return intersection.distance(to: intersectionLocations[index])
                        }
                    let filteredIntersectionDistances = intersectionDensity.enabled
                        ? intersectionDistances.filter { $0 > intersectionDensity.minimumDistanceBetweenIntersections }
                        : intersectionDistances
                    let averageIntersectionDistance = filteredIntersectionDistances
                        .reduce(0.0, +) / Double(filteredIntersectionDistances.count)
                    return averageIntersectionDistance
                }

                return 0.0
            }
        }

        let averageDistanceMultiplier = intersectionDensity.enabled ? intersectionDensity
            .averageDistanceMultiplier : 1.0
        let currentRouteLegIndex = routeProgress.legIndex
        let currentRouteStepIndex = routeProgress.currentLegProgress.stepIndex
        let lookaheadDistance = averageIntersectionDistances[currentRouteLegIndex][currentRouteStepIndex] *
            averageDistanceMultiplier

        return lookaheadDistance
    }
}
