import Foundation
import MapboxDirections

typealias CongestionSegment = ([CLLocationCoordinate2D], CongestionLevel)

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
        10: MGLStyleValue(rawValue: 6),
        13: MGLStyleValue(rawValue: 7),
        16: MGLStyleValue(rawValue: 10),
        19: MGLStyleValue(rawValue: 22),
        22: MGLStyleValue(rawValue: 28)
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
    
    dynamic var trafficUnknownColor: UIColor = .trafficUnknown
    dynamic var trafficLowColor: UIColor = .trafficLow
    dynamic var trafficModerateColor: UIColor = .trafficModerate
    dynamic var trafficHeavyColor: UIColor = .trafficHeavy
    dynamic var trafficSevereColor: UIColor = .trafficSevere
    dynamic var routeCasingColor: UIColor = .defaultRouteCasing
    
    var showsRoute: Bool {
        get {
            return style?.layer(withIdentifier: routeLayerIdentifier) != nil
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
        guard let coordinates = route.coordinates else { return nil }
        
        let congestionPerLeg = route.legs.flatMap {
            $0.segmentCongestionLevels
        }
        
        let combinedCongestionLevel = Array(congestionPerLeg.joined()) // Flatten all leg nodes
        let destination = coordinates.suffix(from: 1)
        let segment = zip(coordinates, destination).map { [$0.0, $0.1] }
        
        guard let leg = congestionPerLeg.first, leg.count == segment.count else {
            let line = MGLPolylineFeature(coordinates: coordinates, count: UInt(coordinates.count))
            line.attributes["congestion"] = "unknown"
            return MGLShapeCollectionFeature(shapes: [line])
        }
        
        let congestionSegments = Array(zip(segment, combinedCongestionLevel))
        
        // Merge adjacent segments with the same congestion level
        var mergedCongestionSegments = [CongestionSegment]()
        for seg in congestionSegments {
            let coordinates = seg.0
            let congestionLevel = seg.1
            if let last = mergedCongestionSegments.last, last.1 == congestionLevel {
                mergedCongestionSegments[mergedCongestionSegments.count - 1].0 += coordinates
            } else {
                mergedCongestionSegments.append(seg)
            }
        }
        
        // Filter out any segments with low congestion
        let nontrivialCongestionSegments = mergedCongestionSegments.filter { $0.1 != CongestionLevel.unknown && $0.1 != CongestionLevel.low }
        
        let baseLine = MGLPolylineFeature(coordinates: coordinates, count: route.coordinateCount)
        baseLine.attributes["congestion"] = "unknown"
        let lines = nontrivialCongestionSegments.map { (congestionSegment: CongestionSegment) -> MGLPolylineFeature in
            let polyline = MGLPolylineFeature(coordinates: congestionSegment.0, count: UInt(congestionSegment.0.count))
            polyline.attributes["congestion"] = String(describing: congestionSegment.1)
            return polyline
        }
        
        return MGLShapeCollectionFeature(shapes: [baseLine] + lines)
    }
    
    func routeStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
        
        let line = MGLLineStyleLayer(identifier: identifier, source: source)
        line.lineWidth = MGLStyleValue(interpolationMode: .exponential,
                                       cameraStops: routeLineWidthAtZoomLevels,
                                       options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.5)])
        
        line.lineColor = MGLStyleValue(interpolationMode: .categorical, sourceStops: [
            "unknown": MGLStyleValue(rawValue: trafficUnknownColor),
            "low": MGLStyleValue(rawValue: trafficLowColor),
            "moderate": MGLStyleValue(rawValue: trafficModerateColor),
            "heavy": MGLStyleValue(rawValue: trafficHeavyColor),
            "severe": MGLStyleValue(rawValue: trafficSevereColor)
            ], attributeName: "congestion", options: nil)
        
        line.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        
        return line
    }
    
    func routeCasingStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
        
        let lineCasing = MGLLineStyleLayer(identifier: identifier, source: source)
        
        // Take the default line width and make it wider for the casing
        var newCameraStop:[Int:MGLStyleValue<NSNumber>] = [:]
        for stop in routeLineWidthAtZoomLevels {
            let f = stop.value as! MGLConstantStyleValue
            let newValue =  f.rawValue.doubleValue * 1.5
            newCameraStop[stop.key] = MGLStyleValue<NSNumber>(rawValue: NSNumber(value:newValue))
        }
        
        lineCasing.lineWidth = MGLStyleValue(interpolationMode: .exponential,
                                             cameraStops: newCameraStop,
                                             options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.5)])
        
        lineCasing.lineColor = MGLStyleValue(rawValue: routeCasingColor)
        lineCasing.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        lineCasing.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        
        return lineCasing
    }
}

@objc
public protocol NavigationMapViewDelegate: class  {
    @objc(navigationMapView:shouldUpdateToLocation:)
    optional func navigationMapView(_ mapView: NavigationMapView, shouldUpdateTo location: CLLocation) -> CLLocation?
    
    @objc optional func navigationMapView(_ mapView: NavigationMapView, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    @objc optional func navigationMapView(_ mapView: NavigationMapView, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    @objc(navigationMapView:shapeDescribingRoute:)
    optional func navigationMapView(_ mapView: NavigationMapView, shapeDescribing route: Route) -> MGLShape?
    
    @objc(navigationMapView:simplifiedShapeDescribingRoute:)
    optional func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeDescribing route: Route) -> MGLShape?
}
