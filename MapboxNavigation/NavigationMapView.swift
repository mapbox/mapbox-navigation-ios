import Foundation
import MapboxDirections

@objc(MBNavigationMapView)
open class NavigationMapView: MGLMapView {
    
    let sourceIdentifier = "routeSource"
    let sourceCasingIdentifier = "routeCasingSource"
    let routeLayerIdentifier = "routeLayer"
    let routeLayerCasingIdentifier = "routeLayerCasing"
    
    public weak var navigationMapDelegate: NavigationMapViewDelegate?
    
    open override func locationManager(_ manager: CLLocationManager!, didUpdateLocations locations: [CLLocation]!) {
        guard let location = locations.first else { return }
        
        if let modifiedLocation = navigationMapDelegate?.navigationMapView?(self, shouldUpdateTo: location) {
            super.locationManager(manager, didUpdateLocations: [modifiedLocation])
        } else {
            super.locationManager(manager, didUpdateLocations: locations)
        }
    }
    
    /**
     Adds or updates both the route line and the route line casing
     */
    public func showRoute(_ route: Route) {
        guard let style = style else {
            return
        }
        
        let polyline = navigationMapDelegate?.navigationMapView?(self, shapeDescribing: route) ?? shape(describing: route)
        let polylineSimplified = navigationMapDelegate?.navigationMapView?(self, simplifiedShapeDescribing: route) ?? polyline
        
        if let source = style.source(withIdentifier: sourceIdentifier) as? MGLShapeSource {
            source.shape = polyline
        } else if let source = style.source(withIdentifier: sourceCasingIdentifier) as? MGLShapeSource {
            source.shape = polylineSimplified
        } else {
            let lineSource = MGLShapeSource(identifier: sourceIdentifier, shape: polyline, options: nil)
            let lineCasingSource = MGLShapeSource(identifier: sourceCasingIdentifier, shape: polylineSimplified, options: nil)
            style.addSource(lineSource)
            style.addSource(lineCasingSource)
            
            let line = navigationMapDelegate?.navigationMapView?(self, routeStyleLayerWithIdentifier: routeLayerIdentifier, source: lineSource) ?? routeStyleLayer(identifier: routeLayerIdentifier, source: lineSource)
            let lineCasing = navigationMapDelegate?.navigationMapView?(self, routeCasingStyleLayerWithIdentifier: routeLayerCasingIdentifier, source: lineSource) ?? routeCasingStyleLayer(identifier: routeLayerCasingIdentifier, source: lineSource)
            
            for layer in style.layers.reversed() {
                if !(layer is MGLSymbolStyleLayer) &&
                    layer.identifier != arrowLayerIdentifier && layer.identifier != arrowSourceIdentifier {
                    style.insertLayer(line, above: layer)
                    style.insertLayer(lineCasing, below: line)
                    return
                }
            }
        }
    }
    
    /**
     Removes route line and route line casing from map
     */
    public func removeRoute() {
        guard let style = style else {
            return
        }
        
        if let line = style.layer(withIdentifier: routeLayerIdentifier) {
            style.removeLayer(line)
        }
        
        if let lineCasing = style.layer(withIdentifier: routeLayerCasingIdentifier) {
            style.removeLayer(lineCasing)
        }
        
        if let lineSource = style.source(withIdentifier: sourceIdentifier) {
            style.removeSource(lineSource)
        }
        
        if let lineCasingSource = style.source(withIdentifier: sourceCasingIdentifier) {
            style.removeSource(lineCasingSource)
        }
    }
    
    func shape(describing route: Route) -> MGLShape? {
        guard var coordinates = route.coordinates else {
            return nil
        }
        
        return MGLPolylineFeature(coordinates: &coordinates, count: route.coordinateCount)
    }
    
    func routeStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
        
        let line = MGLLineStyleLayer(identifier: identifier, source: source)
        
        line.lineColor = MGLStyleValue(rawValue: .defaultRouteLayer)
        line.lineWidth = MGLStyleValue(rawValue: 5)
        
        line.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        line.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        
        return line
    }
    
    func routeCasingStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
        
        let lineCasing = MGLLineStyleLayer(identifier: identifier, source: source)
        
        lineCasing.lineColor = MGLStyleValue(rawValue: .defaultRouteCasing)
        lineCasing.lineWidth = MGLStyleValue(rawValue: 9)
        
        lineCasing.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        lineCasing.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        
        return lineCasing
    }
}

@objc
public protocol NavigationMapViewDelegate: class  {
    @objc optional func navigationMapView(_ mapView: NavigationMapView, shouldUpdateTo location: CLLocation) -> CLLocation?
    @objc optional func navigationMapView(_ mapView: NavigationMapView, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    @objc optional func navigationMapView(_ mapView: NavigationMapView, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    @objc optional func navigationMapView(_ mapView: NavigationMapView, shapeDescribing route: Route) -> MGLShape?
    @objc optional func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeDescribing route: Route) -> MGLShape?
}
