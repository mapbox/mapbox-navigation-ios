import Foundation
import Mapbox
import MapboxDirections
import MapboxGeocoder

let sourceIdentifier = "routeSourceID"
let routeLayerIdentifier = "routeLayerIdentifier"
let routeLayerCasingIdentifier = "routeLayerCasingIdentifier"

extension MGLMapView {
    public func show(_ placemark: GeocodedPlacemark) {
        if let bounds = placemark.coordinateBounds {
            setVisibleCoordinateBounds(bounds, animated: true)
        } else {
            setCenter(placemark.location.coordinate, zoomLevel: placemark.preferredZoomLevel, animated: true)
        }
    }
    
    public func annotate(_ routes: [Route], clearMap: Bool) {
        
        // We don't support alternative routes at this point
        guard let route = routes.first, var coordinates = route.coordinates else {
            return
        }
        
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
        
        let polyline = MGLPolylineFeature(coordinates: &coordinates, count: route.coordinateCount)
        let geoJSONSource = MGLShapeSource(identifier: sourceIdentifier, shape: polyline, options: nil)
        let line = MGLLineStyleLayer(identifier: routeLayerIdentifier, source: geoJSONSource)
        let lineCasing = MGLLineStyleLayer(identifier: routeLayerCasingIdentifier, source: geoJSONSource)
        
        line.lineColor = MGLStyleValue(rawValue: NavigationUI.shared.tintStrokeColor.withAlphaComponent(0.6))
        line.lineWidth = MGLStyleValue(rawValue: 5)
        lineCasing.lineColor = MGLStyleValue(rawValue: NavigationUI.shared.tintStrokeColor)
        lineCasing.lineWidth = MGLStyleValue(rawValue: 9)
        
        let cap = NSValue(mglLineCap: .round)
        let join = NSValue(mglLineJoin: .round)
        
        line.lineCap = MGLStyleValue(rawValue: cap)
        line.lineJoin = MGLStyleValue(rawValue: join)
        lineCasing.lineCap = MGLStyleValue(rawValue: cap)
        lineCasing.lineJoin = MGLStyleValue(rawValue: join)
        
        style.addSource(geoJSONSource)
        
        for layer in style.layers.reversed() {
            if let layer = layer as? MGLStyleLayer, !(layer is MGLSymbolStyleLayer) {
                style.insertLayer(line, above: layer)
                style.insertLayer(lineCasing, below: line)
                return
            }
        }
    }
    
    public var showsTraffic: Bool {
        get {
            if let style = style {
                for layer in style.layers {
                    if let l = layer as? MGLForegroundStyleLayer {
                        if l.sourceIdentifier == "mapbox://mapbox.mapbox-traffic-v1" {
                            return l.isVisible
                        }
                    }
                }
            }
            return false
        }
        set {
            if let style = style {
                for layer in style.layers {
                    if let layer = layer as? MGLForegroundStyleLayer {
                        if layer.sourceIdentifier == "mapbox://mapbox.mapbox-traffic-v1" {
                            layer.isVisible = newValue
                        }
                    }
                }
            }
        }
    }
}
