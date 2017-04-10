import Foundation
import MapboxDirections

@objc(MBNavigationMapView)
open class NavigationMapView: MGLMapView {
    
    weak var navigationMapDelegate: NavigationMapViewDelegate?
    
    open override func locationManager(_ manager: CLLocationManager!, didUpdateLocations locations: [Any]!) {
        guard let location = locations.first as? CLLocation else { return }
        
        if let modifiedLocation = navigationMapDelegate?.navigationMapView(self, shouldUpdateTo: location) {
            super.locationManager(manager, didUpdateLocations: [modifiedLocation])
        } else {
            super.locationManager(manager, didUpdateLocations: locations)
        }
    }
    
    /**
     Annotates the map with a route line.
     */
    open func annotate(_ route: Route) {
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
        
        let polyline = shape(describing: route)
        
        if let source = style.source(withIdentifier: sourceIdentifier) as? MGLShapeSource {
            source.shape = polyline
        } else {
            let lineSource = MGLShapeSource(identifier: sourceIdentifier, shape: polyline, options: nil)
            style.addSource(lineSource)
            
            let line = routeStyleLayer(identifier: routeLayerIdentifier, source: lineSource)
            let lineCasing = routeCasingStyleLayer(identifier: routeLayerCasingIdentifier, source: lineSource)
            
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
    
    open func shape(describing route: Route) -> MGLShape? {
        guard var coordinates = route.coordinates else {
            return nil
        }
        
        return MGLPolylineFeature(coordinates: &coordinates, count: route.coordinateCount)
    }
    
    /**
     Function for overriding the default route line style.
     */
    open func routeStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
        
        let line = MGLLineStyleLayer(identifier: identifier, source: source)
        
        line.lineColor = MGLStyleValue(rawValue: NavigationUI.shared.tintStrokeColor.withAlphaComponent(0.6))
        line.lineWidth = MGLStyleValue(rawValue: 5)
        
        line.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        line.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        
        return line
    }
    
    /**
     Function for overriding the default route line casing style.
     */
    open func routeCasingStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
        
        let lineCasing = MGLLineStyleLayer(identifier: identifier, source: source)
        
        lineCasing.lineColor = MGLStyleValue(rawValue: NavigationUI.shared.tintStrokeColor)
        lineCasing.lineWidth = MGLStyleValue(rawValue: 9)
        
        lineCasing.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        lineCasing.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        
        return lineCasing
    }
}
