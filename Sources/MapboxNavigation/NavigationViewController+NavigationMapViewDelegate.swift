import MapboxMaps
import MapboxDirections
import MapboxCoreNavigation

// MARK: NavigationMapViewDelegate methods

extension NavigationViewController: NavigationMapViewDelegate {
    
    public func navigationMapView(_ navigationMapView: NavigationMapView,
                                  routeLineLayerWithIdentifier identifier: String,
                                  sourceIdentifier: String) -> LineLayer? {
        delegate?.navigationViewController(self,
                                           routeLineLayerWithIdentifier: identifier,
                                           sourceIdentifier: sourceIdentifier)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView,
                                  routeCasingLineLayerWithIdentifier identifier: String,
                                  sourceIdentifier: String) -> LineLayer? {
        delegate?.navigationViewController(self,
                                           routeCasingLineLayerWithIdentifier: identifier,
                                           sourceIdentifier: sourceIdentifier)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView,
                                  routeRestrictedAreasLineLayerWithIdentifier identifier: String,
                                  sourceIdentifier: String) -> LineLayer? {
        delegate?.navigationViewController(self,
                                           routeRestrictedAreasLineLayerWithIdentifier: identifier,
                                           sourceIdentifier: sourceIdentifier)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView,
                                  willAdd layer: Layer) -> Layer? {
        delegate?.navigationViewController(self,
                                           willAdd: layer)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView,
                                  waypointCircleLayerWithIdentifier identifier: String,
                                  sourceIdentifier: String) -> CircleLayer? {
        delegate?.navigationViewController(self,
                                           waypointCircleLayerWithIdentifier: identifier,
                                           sourceIdentifier: sourceIdentifier)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView,
                                  waypointSymbolLayerWithIdentifier identifier: String,
                                  sourceIdentifier: String) -> SymbolLayer? {
        delegate?.navigationViewController(self,
                                           waypointSymbolLayerWithIdentifier: identifier,
                                           sourceIdentifier: sourceIdentifier)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView,
                                  shapeFor waypoints: [Waypoint],
                                  legIndex: Int) -> FeatureCollection? {
        delegate?.navigationViewController(self,
                                           shapeFor: waypoints,
                                           legIndex: legIndex)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView,
                                  didAdd finalDestinationAnnotation: PointAnnotation,
                                  pointAnnotationManager: PointAnnotationManager) {
        delegate?.navigationViewController(self,
                                           didAdd: finalDestinationAnnotation,
                                           pointAnnotationManager: pointAnnotationManager)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView,
                                  didSelect waypoint: Waypoint) {
        delegate?.navigationViewController(self,
                                           didSelect: waypoint)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView,
                                  didSelect continuousAlternative: AlternativeRoute) {
        router.updateRoute(with: continuousAlternative.indexedRouteResponse,
                           routeOptions: nil,
                           completion: nil)
        
        delegate?.navigationViewController(self,
                                           didSelect: continuousAlternative)
    }
}
