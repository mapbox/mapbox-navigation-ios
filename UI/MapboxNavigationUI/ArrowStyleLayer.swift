import Foundation
import Mapbox
import MapboxDirections
import MapboxNavigation

class ArrowStyleLayer {
    
    class func add(nextStep: RouteProgress,
                   mapView: MGLMapView,
                   currentManeuverArrowStrokePolylines: inout [ArrowFillPolyline],
                   currentManeuverArrowPolylines: inout [ArrowFillPolyline]) {
        
        let maneuverCoordinate = nextStep.currentLegProgress.upComingStep?.maneuverLocation
        let polylineCoordinates = nextStep.route.coordinates
        
        let shaftLength = max(min(50 * mapView.metersPerPoint(atLatitude: maneuverCoordinate!.latitude), 50), 10)
        let shaftCoordinates = polyline(along: polylineCoordinates!, within: -shaftLength / 2, of: maneuverCoordinate!)
            + polyline(along: polylineCoordinates!, within: shaftLength, of: maneuverCoordinate!)
        
        if shaftCoordinates.count > 1 {
            let shaftStrokeLength = shaftLength * 1.1
            var shaftStrokeCoordinates = polyline(along: polylineCoordinates!, within: -shaftStrokeLength / 2, of: maneuverCoordinate!)
                + polyline(along: polylineCoordinates!, within: shaftLength, of: maneuverCoordinate!)
            let shaftStrokePolyline = ArrowStrokePolyline(coordinates: &shaftStrokeCoordinates, count: UInt(shaftStrokeCoordinates.count))
            
            currentManeuverArrowStrokePolylines = [shaftStrokePolyline]
            
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
            
            currentManeuverArrowStrokePolylines.append(headStrokePolyline)
            
            var leftHookCoordinates = shaftCoordinates + [leftTipCoordinate]
            let leftHookPolyline = ArrowFillPolyline(coordinates: &leftHookCoordinates, count: UInt(leftHookCoordinates.count))
            currentManeuverArrowPolylines = [leftHookPolyline]
            var rightHookCoordinates = shaftCoordinates + [rightTipCoordinate]
            let rightHookPolyline = ArrowFillPolyline(coordinates: &rightHookCoordinates, count: UInt(rightHookCoordinates.count))
            currentManeuverArrowPolylines.append(rightHookPolyline)
            
            currentManeuverArrowPolylines.append(headStrokePolyline)
            
            let arrowSource = MGLShapeSource(identifier: "arrowSource", shape: MGLShapeCollection(shapes: currentManeuverArrowPolylines), options: nil)
            let arrow = MGLLineStyleLayer(identifier: "arrow", source: arrowSource)
            
            arrow.lineWidth = MGLStyleValue(rawValue: 6)
            arrow.lineColor = MGLStyleValue(rawValue: .white)
            
            // Arrow stroke
            let arrowSourceStroke = MGLShapeSource(identifier: "arrowSourceStroke", shape: MGLShapeCollection(shapes: currentManeuverArrowStrokePolylines), options: nil)
            let arrowStroke = MGLLineStyleLayer(identifier: "arrowStroke", source: arrowSourceStroke)
            
            let cap = NSValue(mglLineCap: .round)
            let join = NSValue(mglLineJoin: .round)
            
            arrowStroke.lineCap = MGLStyleValue(rawValue: cap)
            arrowStroke.lineJoin = MGLStyleValue(rawValue: join)
            arrow.lineCap = MGLStyleValue(rawValue: cap)
            arrow.lineJoin = MGLStyleValue(rawValue: join)
            
            arrowStroke.lineWidth = MGLStyleValue(rawValue: 8)
            arrowStroke.lineColor = MGLStyleValue(rawValue: Theme.shared.tintColor)
            mapView.style?.addSource(arrowSourceStroke)
            mapView.style?.addSource(arrowSource)
            
            mapView.style?.addLayer(arrow)
            mapView.style?.insertLayer(arrowStroke, below: arrow)
        }
    }
    
    class func remove(from mapView: MGLMapView) {
        guard let style = mapView.style else {
            return
        }
        
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

