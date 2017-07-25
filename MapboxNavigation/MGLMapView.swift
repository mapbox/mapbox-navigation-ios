import Foundation
import Mapbox
import MapboxDirections
import MapboxCoreNavigation

let arrowSourceIdentifier = "arrowSource"
let arrowSourceStrokeIdentifier = "arrowSourceStroke"
let arrowLayerIdentifier = "arrowLayer"

/**
 An extension on `MGLMapView` that allows for toggling traffic on a map style that contains a [Mapbox Traffic source](https://www.mapbox.com/vector-tiles/mapbox-traffic-v1/).
 */
extension MGLMapView {

    /**
     Toggle traffic on a map style that contains a Mapbox Traffic source.
     */
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
        
        guard let style = style else {
            return
        }
        
        let shaftLength = max(min(50 * metersPerPoint(atLatitude: maneuverCoordinate!.latitude), 50), 10)
        let shaftCoordinates = Array(polyline(along: polylineCoordinates!, within: -shaftLength / 2, of: maneuverCoordinate!).reversed()
            + polyline(along: polylineCoordinates!, within: shaftLength, of: maneuverCoordinate!).suffix(from: 1))
        
        if shaftCoordinates.count > 1 {
            let shaftStrokeLength = shaftLength * 1.1
            var shaftStrokeCoordinates = Array(polyline(along: polylineCoordinates!, within: -shaftStrokeLength / 2, of: maneuverCoordinate!).reversed()
                + polyline(along: polylineCoordinates!, within: shaftLength, of: maneuverCoordinate!).suffix(from: 1))
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
            
            let arrowShape = MGLShapeCollection(shapes: maneuverArrowPolylines)
            let arrowStrokeShape = MGLShapeCollection(shapes: maneuverArrowStrokePolylines)
            
            let cap = NSValue(mglLineCap: .round)
            let join = NSValue(mglLineJoin: .round)
            
            let arrowSourceStroke = MGLShapeSource(identifier: arrowSourceStrokeIdentifier, shape: arrowStrokeShape, options: nil)
            let arrowStroke = MGLLineStyleLayer(identifier: arrowSourceIdentifier, source: arrowSourceStroke)
            let arrowSource = MGLShapeSource(identifier: arrowSourceIdentifier, shape: arrowShape, options: nil)
            let arrow = MGLLineStyleLayer(identifier: arrowLayerIdentifier, source: arrowSource)
            
            if let source = style.source(withIdentifier: arrowSourceIdentifier) as? MGLShapeSource {
                source.shape = arrowShape
            } else {
                arrow.minimumZoomLevel = 14.5
                arrow.lineCap = MGLStyleValue(rawValue: cap)
                arrow.lineJoin = MGLStyleValue(rawValue: join)
                arrow.lineWidth = MGLStyleValue(rawValue: 6)
                arrow.lineColor = MGLStyleValue(rawValue: .white)
                
                style.addSource(arrowSource)
                style.addLayer(arrow)
            }
            
            if let source = style.source(withIdentifier: arrowSourceStrokeIdentifier) as? MGLShapeSource {
                source.shape = arrowStrokeShape
            } else {
                
                arrowStroke.minimumZoomLevel = 14.5
                arrowStroke.lineCap = MGLStyleValue(rawValue: cap)
                arrowStroke.lineJoin = MGLStyleValue(rawValue: join)
                arrowStroke.lineWidth = MGLStyleValue(rawValue: 8)
                arrowStroke.lineColor = MGLStyleValue(rawValue: .defaultArrowStroke)
                
                style.addSource(arrowSourceStroke)
                style.insertLayer(arrowStroke, below: arrow)
            }
        }
    }
}
