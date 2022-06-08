import Foundation
import UIKit
import MapboxDirections
import MapboxCoreNavigation

extension NavigationMapView {
    func onUpdateAlternatives(_ updatedAlternatives: [AlternativeRoute], removedAlternatives: [AlternativeRoute]) {
        show(continuousAlternatives:updatedAlternatives)
    }

    func onFailToUpdateAlternatives(_ error: AlternativeRouteError) {
        show([])
    }
    
    /**
     Visualizes the given alternative routes, removing any existing from the map.
     
     Each route is visualized as a line. Each route is displayed as a separate line as an inactive route, drawn from it's deviation point and below the main route line.
     
     To undo the effects of this method, use the `removeContinuousAlternativesRoutes()` method.
     
     - parameter continuousAlternatives: The routes to visualize.
     */
    public func show(continuousAlternatives: [AlternativeRoute]) {
        
        removeContinuousAlternativesRoutes()
        
        self.continuousAlternatives = continuousAlternatives
        
        guard let routes = self.routes,
              !routes.isEmpty && showsContinuousAlternatives else { return }
        
        applyRoutesDisplay()
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
    }
    
    /**
     Returns a list of the `AlternativeRoute`s, that are close to a certain point and are within threshold distance
     defined in `NavigationMapView.tapGestureDistanceThreshold`.
     
     - parameter point: Point on the screen.
     - returns: List of the alternative routes, which were found. If there are no continuous alternatives routes on the map view `nil`
     will be returned.
     */
    public func continuousAlternativeRoutes(closeTo point: CGPoint) -> [AlternativeRoute]? {
        // Filter routes with at least 2 coordinates.
        let routes = continuousAlternatives?.enumerated().compactMap { (item: EnumeratedSequence<[AlternativeRoute]>.Element) -> (Route, Int)? in
            guard let route = item.element.indexedRouteResponse.currentRoute else {
                return nil
            }
            return (route, item.offset)
        }
        guard let routes = routes?.filter({ $0.0.shape?.coordinates.count ?? 0 > 1 }) else { return nil }
        
        // Sort routes by closest distance to tap gesture.
        let tapCoordinate = mapView.mapboxMap.coordinate(for: point)
        let closest = routes.sorted { (left, right) -> Bool in
            // Existence has been assured through use of filter.
            let leftLine = left.0.shape!
            let rightLine = right.0.shape!
            let leftDistance = leftLine.closestCoordinate(to: tapCoordinate)!.coordinate.distance(to: tapCoordinate)
            let rightDistance = rightLine.closestCoordinate(to: tapCoordinate)!.coordinate.distance(to: tapCoordinate)
            
            return leftDistance < rightDistance
        }
        
        // Filter closest coordinates by which ones are under threshold.
        let candidates = closest.filter {
            let closestCoordinate = $0.0.shape!.closestCoordinate(to: tapCoordinate)!.coordinate
            let closestPoint = mapView.mapboxMap.point(for: closestCoordinate)
            
            return closestPoint.distance(to: point) < tapGestureDistanceThreshold
        }
        
        return candidates.compactMap { continuousAlternatives?[$0.1] }
    }
}
