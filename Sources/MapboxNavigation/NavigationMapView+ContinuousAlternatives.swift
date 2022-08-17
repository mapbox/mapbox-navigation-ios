import Foundation
import UIKit
import MapboxDirections
import MapboxCoreNavigation
import Turf

extension NavigationMapView {
    /**
     Visualizes the given alternative routes, removing any existing from the map.
     
     Each route is visualized as a line. Each route is displayed as a separate line as an inactive route, drawn from it's deviation point and below the main route line.
     
     To undo the effects of this method, use the `removeContinuousAlternativesRoutes()` method.
     
     - parameter continuousAlternatives: The routes to visualize.
     */
    public func show(continuousAlternatives: [AlternativeRoute]) {
        
        removeContinuousAlternativesRoutes()
        
        self.continuousAlternatives = continuousAlternatives
        
        showContinuousAlternativeRoutesDurations()
        
        updateRouteLineWithRouteLineTracksTraversal()
    }
    
    func removeContinuousAlternativesRoutesLayers() {
        var sourceIdentifiers = Set<String>()
        var layerIdentifiers = Set<String>()
        
        continuousAlternatives?.compactMap(\.indexedRouteResponse.currentRoute).forEach {
            sourceIdentifiers.insert($0.identifier(.source(isMainRoute: false, isSourceCasing: true)))
            sourceIdentifiers.insert($0.identifier(.source(isMainRoute: false, isSourceCasing: false)))
            sourceIdentifiers.insert($0.identifier(.restrictedRouteAreaSource))
            layerIdentifiers.insert($0.identifier(.route(isMainRoute: false)))
            layerIdentifiers.insert($0.identifier(.routeCasing(isMainRoute: false)))
            layerIdentifiers.insert($0.identifier(.restrictedRouteAreaRoute))
        }
        
        mapView.mapboxMap.style.removeLayers(layerIdentifiers)
        mapView.mapboxMap.style.removeSources(sourceIdentifiers)
    }
    
    /**
     Remove any lines visualizing continuous alternatives routes from the map.
     
     This method undoes the effects of the `show(continuousAlternatives:)` method.
     */
    public func removeContinuousAlternativesRoutes() {
        removeContinuousAlternativesRoutesLayers()
        
        continuousAlternatives = nil
        
        showContinuousAlternativeRoutesDurations()
    }
    
    /**
     Returns a list of the `AlternativeRoute`s, that are close to a certain point and are within threshold distance
     defined in `NavigationMapView.tapGestureDistanceThreshold`.
     
     - parameter point: Point on the screen.
     - returns: List of the alternative routes, which were found. If there are no continuous alternatives routes on the map view `nil`
     will be returned.
     */
    public func continuousAlternativeRoutes(closeTo point: CGPoint) -> [AlternativeRoute]? {
        guard let continuousAlternatives = continuousAlternatives,
              !continuousAlternatives.isEmpty else {
            return nil
        }
        
        // Workaround for XCode 12.5 compilation bug
        typealias RouteWithMetadata = (route: Route, index: Int, distance: LocationDistance)
        
        // Filter routes with at least 2 coordinates and within tap distance.
        let tapCoordinate = mapView.mapboxMap.coordinate(for: point)
        let routes = continuousAlternatives.enumerated().compactMap { (item: EnumeratedSequence<[AlternativeRoute]>.Element) -> RouteWithMetadata? in
            guard let route = item.element.indexedRouteResponse.currentRoute else {
                return nil
            }
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
            
            return RouteWithMetadata(route: route,
                                     index: item.offset,
                                     distance: closestCoordinate.distance(to: tapCoordinate))
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
