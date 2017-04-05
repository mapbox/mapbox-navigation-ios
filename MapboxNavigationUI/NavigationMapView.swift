import Foundation
import MapboxDirections

open class NavigationMapView: MGLMapView {
    
    var navigationMapDelegate: NavigationMapViewDelegate?
    
    let cap = NSValue(mglLineCap: .round)
    let join = NSValue(mglLineJoin: .round)
    
    open override func locationManager(_ manager: CLLocationManager!, didUpdateLocations locations: [Any]!) {
        guard let location = locations.first as? CLLocation else { return }
        
        if let modifiedLocation = navigationMapDelegate?.navigationMapView(self, shouldUpdateTo: location) {
            super.locationManager(manager, didUpdateLocations: [modifiedLocation])
        } else {
            super.locationManager(manager, didUpdateLocations: locations)
        }
    }
    
    public func annotate(_ route: Route) {
        guard let style = style else {
            return
        }
        
        if let line = style.layer(withIdentifier: routeLayerIdentifier) {
            style.removeLayer(line)
        }
        
        if let lineCasing = style.layer(withIdentifier: routeLayerCasingIdentifier) {
            style.removeLayer(lineCasing)
        }
        
        if let source = style.source(withIdentifier: sourceIdentifier) {
            style.removeSource(source)
        }
        
        let polyline = shape(for: route)
        
        if let source = style.source(withIdentifier: sourceIdentifier) as? MGLShapeSource {
            source.shape = polyline
        } else {
            let geoJSONSource = MGLShapeSource(identifier: sourceIdentifier, shape: polyline, options: nil)
            style.addSource(geoJSONSource)
            
            let line = lineStyle(MGLLineStyleLayer(identifier: routeLayerIdentifier, source: geoJSONSource))
            let lineCasing = lineCasingStyle(MGLLineStyleLayer(identifier: routeLayerCasingIdentifier, source: geoJSONSource))
            
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
    
    public func shape(for route: Route) -> MGLShape? {
        guard var coordinates = route.coordinates else {
            return nil
        }
        
        return MGLPolylineFeature(coordinates: &coordinates, count: route.coordinateCount)
    }
    
    public func lineStyle(_ line: MGLLineStyleLayer) -> MGLLineStyleLayer {
        let cap = NSValue(mglLineCap: .round)
        let join = NSValue(mglLineJoin: .round)
        
        line.lineColor = MGLStyleValue(rawValue: NavigationUI.shared.tintStrokeColor.withAlphaComponent(0.6))
        line.lineWidth = MGLStyleValue(rawValue: 5)
        
        line.lineCap = MGLStyleValue(rawValue: cap)
        line.lineJoin = MGLStyleValue(rawValue: join)
        
        return line
    }
    
    public func lineCasingStyle(_ lineCasing: MGLLineStyleLayer) -> MGLLineStyleLayer {
        let cap = NSValue(mglLineCap: .round)
        let join = NSValue(mglLineJoin: .round)
        
        lineCasing.lineColor = MGLStyleValue(rawValue: NavigationUI.shared.tintStrokeColor)
        lineCasing.lineWidth = MGLStyleValue(rawValue: 9)
        
        lineCasing.lineCap = MGLStyleValue(rawValue: cap)
        lineCasing.lineJoin = MGLStyleValue(rawValue: join)
        
        return lineCasing
    }
}
