import Foundation
import MapboxDirections

/**
 `NavigationMapView` is a subclass of `MGLMapView` with convenience functions for adding `Route` lines to a map.
 */
@objc(MBNavigationMapView)
open class NavigationMapView: MGLMapView {
    
    let sourceIdentifier = "routeSource"
    let sourceCasingIdentifier = "routeCasingSource"
    let routeLayerIdentifier = "routeLayer"
    let routeLayerCasingIdentifier = "routeLayerCasing"
    
    let routeLineWidthAtZoomLevels: [Int: MGLStyleValue<NSNumber>] = [
        4: MGLStyleValue(rawValue: 2),
        10: MGLStyleValue(rawValue: 3),
        13: MGLStyleValue(rawValue: 4),
        16: MGLStyleValue(rawValue: 7),
        19: MGLStyleValue(rawValue: 14),
        22: MGLStyleValue(rawValue: 18)
    ]
    
    var manuallyUpdatesLocation: Bool = false {
        didSet {
            if manuallyUpdatesLocation {
                locationManager.stopUpdatingLocation()
                locationManager.stopUpdatingHeading()
                locationManager.delegate = nil
            } else {
                validateLocationServices()
            }
        }
    }
    
    public weak var navigationMapDelegate: NavigationMapViewDelegate?
    
    override open func locationManager(_ manager: CLLocationManager!, didUpdateLocations locations: [CLLocation]!) {
        guard let location = locations.first else { return }
        
        if let modifiedLocation = navigationMapDelegate?.navigationMapView?(self, shouldUpdateTo: location) {
            super.locationManager(manager, didUpdateLocations: [modifiedLocation])
        } else {
            super.locationManager(manager, didUpdateLocations: locations)
        }
    }
    
    override open func validateLocationServices() {
        if !manuallyUpdatesLocation {
            super.validateLocationServices()
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
        
        if let source = style.source(withIdentifier: sourceIdentifier) as? MGLShapeSource,
            let sourceSimplified = style.source(withIdentifier: sourceCasingIdentifier) as? MGLShapeSource {
            source.shape = polyline
            sourceSimplified.shape = polylineSimplified
        } else {
            let lineSource = MGLShapeSource(identifier: sourceIdentifier, shape: polyline, options: nil)
            let lineCasingSource = MGLShapeSource(identifier: sourceCasingIdentifier, shape: polylineSimplified, options: nil)
            style.addSource(lineSource)
            style.addSource(lineCasingSource)
            
            let line = navigationMapDelegate?.navigationMapView?(self, routeStyleLayerWithIdentifier: routeLayerIdentifier, source: lineSource) ?? routeStyleLayer(identifier: routeLayerIdentifier, source: lineSource)
            let lineCasing = navigationMapDelegate?.navigationMapView?(self, routeCasingStyleLayerWithIdentifier: routeLayerCasingIdentifier, source: lineCasingSource) ?? routeCasingStyleLayer(identifier: routeLayerCasingIdentifier, source: lineSource)
            
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
        
        line.lineWidth = MGLStyleValue(interpolationMode: .exponential,
                                       cameraStops: routeLineWidthAtZoomLevels,
                                       options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.5)])
        
        line.lineColor = MGLStyleValue(rawValue: .defaultRouteLayer)
        line.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        line.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        
        return line
    }
    
    func routeCasingStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
        
        let lineCasing = MGLLineStyleLayer(identifier: identifier, source: source)
        
        // Take the default line width and make it wider for the casing
        var newCameraStop:[Int:MGLStyleValue<NSNumber>] = [:]
        for stop in routeLineWidthAtZoomLevels {
            let f = stop.value as! MGLConstantStyleValue
            let newValue =  f.rawValue.doubleValue * 2
            newCameraStop[stop.key] = MGLStyleValue<NSNumber>(rawValue: NSNumber(value:newValue))
        }

        lineCasing.lineWidth = MGLStyleValue(interpolationMode: .exponential,
                                             cameraStops: newCameraStop,
                                             options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.5)])
        
        lineCasing.lineColor = MGLStyleValue(rawValue: .defaultRouteCasing)
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
