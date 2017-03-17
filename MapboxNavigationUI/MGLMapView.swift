import Foundation
import Mapbox
import MapboxDirections
import MapboxNavigation

let sourceIdentifier = "routeSource"
let routeLayerIdentifier = "routeLayer"
let routeLayerCasingIdentifier = "routeLayerCasing"

extension MGLMapView {
    
    public func annotate(_ routes: [Route], clearMap: Bool) {
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
    
    func addArrow(_ routeProgress: RouteProgress) {
        let maneuverCoordinate = routeProgress.currentLegProgress.upComingStep?.maneuverLocation
        let polylineCoordinates = routeProgress.route.coordinates
        
        let shaftLength = max(min(50 * metersPerPoint(atLatitude: maneuverCoordinate!.latitude), 50), 10)
        let shaftCoordinates = polyline(along: polylineCoordinates!, within: -shaftLength / 2, of: maneuverCoordinate!)
            + polyline(along: polylineCoordinates!, within: shaftLength, of: maneuverCoordinate!)
        
        if shaftCoordinates.count > 1 {
            let shaftStrokeLength = shaftLength * 1.1
            var shaftStrokeCoordinates = polyline(along: polylineCoordinates!, within: -shaftStrokeLength / 2, of: maneuverCoordinate!)
                + polyline(along: polylineCoordinates!, within: shaftLength, of: maneuverCoordinate!)
            let shaftStrokePolyline = ArrowStrokePolyline(coordinates: &shaftStrokeCoordinates, count: UInt(shaftStrokeCoordinates.count))
            
            var maneuverArrowStrokePolylines = [shaftStrokePolyline]
            
            let headRadius = shaftLength / 2
            let tipCoordinate = shaftStrokeCoordinates.last!
            let shaftDirection = tipCoordinate.direction(to: shaftStrokeCoordinates[shaftStrokeCoordinates.count - 2])
            let leftTipCoordinate = tipCoordinate.coordinate(at: headRadius, facing: shaftDirection - 45)
            let rightTipCoordinate = tipCoordinate.coordinate(at: headRadius, facing: shaftDirection + 45)
            
            let headStrokeRadius = headRadius * 1.05
            let leftStrokeTipCoordinate = tipCoordinate.coordinate(at: headStrokeRadius, facing: shaftDirection - 45)
            let rightStrokeTipCoordinate = tipCoordinate.coordinate(at: headStrokeRadius, facing: shaftDirection + 45)
            var headStrokeCoordinates = [leftStrokeTipCoordinate, tipCoordinate, rightStrokeTipCoordinate]
            let headStrokePolyline = ArrowStrokePolyline(coordinates: &headStrokeCoordinates, count: UInt(headStrokeCoordinates.count))
            
            maneuverArrowStrokePolylines.append(headStrokePolyline)
            
            var leftHookCoordinates = shaftCoordinates + [leftTipCoordinate]
            let leftHookPolyline = ArrowFillPolyline(coordinates: &leftHookCoordinates, count: UInt(leftHookCoordinates.count))
            var maneuverArrowPolylines = [leftHookPolyline]
            var rightHookCoordinates = shaftCoordinates + [rightTipCoordinate]
            let rightHookPolyline = ArrowFillPolyline(coordinates: &rightHookCoordinates, count: UInt(rightHookCoordinates.count))
            maneuverArrowPolylines.append(rightHookPolyline)
            
            maneuverArrowPolylines.append(headStrokePolyline)
            
            let arrowSource = MGLShapeSource(identifier: "arrowSource", shape: MGLShapeCollection(shapes: maneuverArrowPolylines), options: nil)
            let arrow = MGLLineStyleLayer(identifier: "arrow", source: arrowSource)
            
            arrow.lineWidth = MGLStyleValue(rawValue: 6)
            arrow.lineColor = MGLStyleValue(rawValue: .white)
            
            // Arrow stroke
            let arrowSourceStroke = MGLShapeSource(identifier: "arrowSourceStroke", shape: MGLShapeCollection(shapes: maneuverArrowStrokePolylines), options: nil)
            let arrowStroke = MGLLineStyleLayer(identifier: "arrowStroke", source: arrowSourceStroke)
            
            let cap = NSValue(mglLineCap: .round)
            let join = NSValue(mglLineJoin: .round)
            
            arrowStroke.lineCap = MGLStyleValue(rawValue: cap)
            arrowStroke.lineJoin = MGLStyleValue(rawValue: join)
            arrow.lineCap = MGLStyleValue(rawValue: cap)
            arrow.lineJoin = MGLStyleValue(rawValue: join)
            
            arrowStroke.lineWidth = MGLStyleValue(rawValue: 8)
            arrowStroke.lineColor = MGLStyleValue(rawValue: NavigationUI.shared.tintColor)
            
            style?.addSource(arrowSourceStroke)
            style?.addSource(arrowSource)
            
            style?.addLayer(arrow)
            style?.insertLayer(arrowStroke, below: arrow)
        }
    }
    
    func removeArrow() {
        guard let style = style else { return }
        
        if let arrow = style.layer(withIdentifier: "arrow") {
            style.removeLayer(arrow)
        }
        
        if let arrow = style.layer(withIdentifier: "arrowStroke") {
            style.removeLayer(arrow)
        }
        
        if let arrowStrokeSourceCheck = style.source(withIdentifier: "arrowSourceStroke") {
            style.removeSource(arrowStrokeSourceCheck)
        }
        
        if let arrowSourceCheck = style.source(withIdentifier: "arrowSource") {
            style.removeSource(arrowSourceCheck)
        }
    }
}
