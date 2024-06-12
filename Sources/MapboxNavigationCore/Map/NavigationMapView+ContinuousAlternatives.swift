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
    func continuousAlternativeRoutes(closeTo point: CGPoint) -> [AlternativeRoute]? {
        guard let continuousAlternatives = routes?.alternativeRoutes,
              !continuousAlternatives.isEmpty
        else {
            return nil
        }

        // Workaround for XCode 12.5 compilation bug
        typealias RouteWithMetadata = (route: Route, index: Int, distance: LocationDistance)

        // Filter routes with at least 2 coordinates and within tap distance.
        let tapCoordinate = mapView.mapboxMap.coordinate(for: point)
        let routes = continuousAlternatives.enumerated()
            .compactMap { (item: EnumeratedSequence<[AlternativeRoute]>.Element) -> RouteWithMetadata? in
                let route = item.element.route
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

                return RouteWithMetadata(
                    route: route,
                    index: item.offset,
                    distance: closestCoordinate.distance(to: tapCoordinate)
                )
            }

        // Sort routes by closest distance to tap gesture.
        let closest = routes.sorted { (lhs: RouteWithMetadata, rhs: RouteWithMetadata) -> Bool in
            return lhs.distance < rhs.distance
        }

        return closest.map { (item: RouteWithMetadata) -> AlternativeRoute in
            continuousAlternatives[item.index]
        }
    }
}
