import _MapboxNavigationHelpers
import Foundation
import MapboxDirections
import Turf
import UIKit

extension NavigationMapView {
    /// Returns a list of the ``AlternativeRoute``s, that are close to a certain point and are within threshold distance
    /// defined in ``NavigationMapView/tapGestureDistanceThreshold``.
    ///
    /// - parameter point: Point on the screen.
    /// - returns: List of the alternative routes, which were found. If there are no continuous alternatives routes on
    /// the map view `nil` will be returned.
    /// An empty array is returned if no alternative route was tapped or if there are multiple equally fitting
    /// routes at the tap coordinate.
    func continuousAlternativeRoutes(closeTo point: CGPoint) -> [AlternativeRoute]? {
        guard let routes, !routes.alternativeRoutes.isEmpty
        else {
            return nil
        }

        // Workaround for XCode 12.5 compilation bug
        typealias RouteWithMetadata = (route: Route, index: Int, distance: LocationDistance)

        let continuousAlternatives = routes.alternativeRoutes
        // Add the main route to detect if the main route is the closest to the point. The main route is excluded from
        // the result array.
        let allRoutes = [routes.mainRoute.route] + continuousAlternatives.map { $0.route }

        // Filter routes with at least 2 coordinates and within tap distance.
        let tapCoordinate = mapView.mapboxMap.coordinate(for: point)
        let routeMetadata = allRoutes.enumerated()
            .compactMap { index, route -> RouteWithMetadata? in
                guard route.shape?.coordinates.count ?? 0 > 1 else {
                    return nil
                }
                guard let closestCoordinate = route.shape?.closestCoordinate(to: tapCoordinate)?.coordinate else {
                    return nil
                }

                let closestPoint = mapView.mapboxMap.point(for: closestCoordinate)
                guard closestPoint.distance(to: point) < tapGestureDistanceThreshold else {
                    return nil
                }
                let distance = closestCoordinate.distance(to: tapCoordinate)
                return RouteWithMetadata(route: route, index: index, distance: distance)
            }

        // Sort routes by closest distance to tap gesture.
        let closest = routeMetadata.sorted { (lhs: RouteWithMetadata, rhs: RouteWithMetadata) -> Bool in
            return lhs.distance < rhs.distance
        }

        // Exclude the routes if the distance is the same and we cannot distinguish the routes.
        if routeMetadata.count > 1, abs(routeMetadata[0].distance - routeMetadata[1].distance) < 1e-6 {
            return []
        }

        return closest.compactMap { (item: RouteWithMetadata) -> AlternativeRoute? in
            guard item.index > 0 else { return nil }
            return continuousAlternatives[item.index - 1]
        }
    }
}
