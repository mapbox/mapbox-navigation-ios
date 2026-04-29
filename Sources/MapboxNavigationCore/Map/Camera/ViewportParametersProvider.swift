import CoreLocation
import Foundation
import MapboxDirections
import UIKit

struct ViewportParametersProvider: Sendable {
    func parameters(
        with navigationLocation: NavigationLocation?,
        navigationHeading: NavigationHeading?,
        navigationProgress: NavigationProgress?,
        viewportPadding: UIEdgeInsets,
        options: NavigationViewportDataSourceOptions
    ) -> ViewportDataSourceState {
        if let navigationProgress {
            let intersectionDensity = options.followingCameraOptions.intersectionDensity
            let stepIndex = navigationProgress.currentLegProgress.stepIndex
            let nextStepIndex = min(stepIndex + 1, navigationProgress.currentLeg.steps.count - 1)

            var remainingCoordinatesOnRoute = navigationProgress.currentLegProgress.currentStepProgress
                .remainingStepCoordinates()
            navigationProgress.currentLeg.steps[nextStepIndex...]
                .lazy
                .compactMap { $0.shape?.coordinates }
                .forEach { stepCoordinates in
                    remainingCoordinatesOnRoute.append(contentsOf: stepCoordinates)
                }

            return .init(
                navigationLocation: navigationLocation,
                navigationHeading: navigationHeading,
                navigationState: .active(
                    .init(
                        coordinatesToManeuver: navigationProgress.currentLegProgress.currentStepProgress
                            .remainingStepCoordinates(),
                        lookaheadDistance: lookaheadDistance(
                            navigationProgress,
                            intersectionDensity: intersectionDensity
                        ),
                        currentLegStepIndex: navigationProgress.currentLegProgress.stepIndex,
                        currentLegSteps: navigationProgress.currentLeg.steps,
                        isRouteComplete: navigationProgress.routeIsComplete == true,
                        remainingCoordinatesOnRoute: remainingCoordinatesOnRoute,
                        transportType: navigationProgress.currentLegProgress.currentStep.transportType,
                        distanceRemainingOnStep: navigationProgress.currentLegProgress.currentStepProgress
                            .distanceRemaining
                    )
                ),
                viewportPadding: viewportPadding
            )
        } else {
            return .init(
                navigationLocation: navigationLocation,
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
        _ navigationProgress: NavigationProgress,
        intersectionDensity: IntersectionDensity
    ) -> CLLocationDistance {
        let averageIntersectionDistances = navigationProgress.route.legs.map { leg -> [CLLocationDistance] in
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
        let currentRouteLegIndex = navigationProgress.legIndex
        let currentRouteStepIndex = navigationProgress.currentLegProgress.stepIndex
        let lookaheadDistance = averageIntersectionDistances[currentRouteLegIndex][currentRouteStepIndex] *
            averageDistanceMultiplier

        return lookaheadDistance
    }
}
