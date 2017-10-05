import UIKit

import Turf
import Mapbox
import MapboxDirections
import MapboxNavigation
@testable import MapboxCoreNavigation

let dotSize = CGSize(width: 15, height: 15)

extension UIColor {
    class var route: UIColor { get { return #colorLiteral(red:0.00, green:0.70, blue:0.99, alpha:1.0) } }
}

class PlotRoute: UIView {
    
    // TODO: Support multiple routes to be able to test reroute behavior
    var route: Route? { didSet { setNeedsDisplay() } }
    var rawLocations: [CLLocation]? { didSet { setNeedsDisplay() } }
    var processedLocations: [CLLocation]? { didSet { setNeedsDisplay() } }
    
    var mapView: MGLMapView?
    var coordinateBounds: MGLCoordinateBounds?
    var routeController: RouteController?
    
    func updateCoordinateBounds() {
        guard let route = route else { return }
        coordinateBounds = route.coordinates!.bounds
        mapView = MGLMapView(frame: bounds)
        let padding = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
        mapView?.setVisibleCoordinateBounds(coordinateBounds!, edgePadding: padding, animated: false)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        updateCoordinateBounds()
        drawRoute()
        drawLocations()
    }
    
    func drawRoute() {
        // Draw a route line
        guard let route = route else { return }
        guard let coordinates = route.coordinates else { return }
        
        let path = UIBezierPath()
        for coordinate in coordinates {
            let position = mapView!.convert(coordinate, toPointTo: self)
            if coordinate == coordinates.first {
                path.move(to: mapView!.convert(coordinates.first!, toPointTo: self))
            } else {
                path.addLine(to: position)
            }
        }
        
        UIColor.route.setStroke()
        path.lineWidth = 4
        path.stroke()
    }
    
    func drawLocations() {
        guard let locations = rawLocations else { return }
        
        // Draw raw locations
        for location in locations {
            let point = mapView!.convert(location.coordinate, toPointTo: self).center(dotSize)
            drawDot(at: point, color: .red)
            drawCourseIndicator(at: point, course: location.course)
            drawCourseText(at: point, course: location.course)
        }
        
        // Draw processed (snapped to line and snapped to course) locations
        guard let route = route else { return }
        let routeController = RouteController(along: route, directions: directions)
        
        for location in locations {
            routeController.rawLocation = location
            if let location = routeController.location {
                let point = mapView!.convert(location.coordinate, toPointTo: self).center(dotSize)
                drawDot(at: point, color: .green)
                drawCourseIndicator(at: point, course: location.course)
                drawCourseText(at: point, course: location.course)
            } else {
                // TODO: Draw reroute
            }
        }
    }
}

extension UIView {
    fileprivate func drawDot(at point: CGPoint, color: UIColor) {
        let path = UIBezierPath(ovalIn: CGRect(origin: point, size: dotSize))
        color.withAlphaComponent(0.5).setFill()
        path.fill()
        UIColor.white.setStroke()
        path.lineWidth = 2
        path.stroke()
    }
    
    fileprivate func drawCourseIndicator(at point: CGPoint, course: CLLocationDirection) {
        let path = UIBezierPath()
        let startPoint = CGPoint(x: point.x + dotSize.width / 2, y: point.y + dotSize.height / 2)
        path.move(to: startPoint)
        
        let angle = CGFloat(CLLocationDirection(270 - course).toRadians())
        path.addLine(to: CGPoint(x: startPoint.x + sin(angle - .pi / 2) * dotSize.width,
                                 y: startPoint.y + cos(angle - .pi / 2) * dotSize.height))
        
        UIColor.white.setStroke()
        path.lineWidth = 2
        path.stroke()
    }
    
    fileprivate func drawCourseText(at point: CGPoint, course: CLLocationDirection) {
        let context = UIGraphicsGetCurrentContext()!
        let textRect = CGRect(origin: point, size: CGSize(width: 50, height: 20))
        let text = "\(Int(round(course)))"
        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = .left
        
        let attributes: [String: Any] = [
            NSFontAttributeName: UIFont.systemFont(ofSize: 7, weight: UIFontWeightMedium),
            NSForegroundColorAttributeName: UIColor.white,
            NSParagraphStyleAttributeName: textStyle,
            NSStrokeColorAttributeName: UIColor.black,
            NSStrokeWidthAttributeName: -1
        ]
        
        let height: CGFloat = text.boundingRect(with: CGSize(width: textRect.width, height: CGFloat.infinity),
                                                options: .usesLineFragmentOrigin, attributes: attributes, context: nil).height
        context.saveGState()
        context.clip(to: textRect)
        let rect = CGRect(x: textRect.minX, y: textRect.minY + (textRect.height - height) / 2, width: textRect.width, height: height)
        text.draw(in: rect, withAttributes: attributes)
        context.restoreGState()
    }
}

extension MGLCoordinateBounds {
    fileprivate var frame: CGRect {
        let maxX = Swift.abs(ne.latitude-sw.latitude)
        let maxY = Swift.abs(ne.longitude-sw.longitude)
        return CGRect(origin: .zero, size: CGSize(width: maxX, height: maxY))
    }
}

extension CGSize {
    fileprivate var radius: CGFloat {
        return width / 2
    }
}

extension CLLocationDirection {
    fileprivate func toRadians() -> CGFloat {
        return CGFloat(self * .pi / 180.0)
    }
}

extension CGPoint {
    fileprivate func center(_ size: CGSize) -> CGPoint {
        return CGPoint(x: self.x - size.width / 2, y: self.y - size.height / 2)
    }
}

extension Array where Element == CLLocationCoordinate2D {
    
    fileprivate var bounds: MGLCoordinateBounds {
        var maximumLatitude: CLLocationDegrees = -80
        var minimumLatitude: CLLocationDegrees = 80
        var maximumLongitude: CLLocationDegrees = -180
        var minimumLongitude: CLLocationDegrees = 180
        
        for coordinate in self {
            maximumLatitude = Swift.max(maximumLatitude, coordinate.latitude)
            minimumLatitude = Swift.min(minimumLatitude, coordinate.latitude)
            maximumLongitude = Swift.max(maximumLongitude, coordinate.longitude)
            minimumLongitude = Swift.min(minimumLongitude, coordinate.longitude)
        }
        
        let sw = CLLocationCoordinate2D(latitude: minimumLatitude, longitude: minimumLongitude)
        let ne = CLLocationCoordinate2D(latitude: maximumLatitude, longitude: maximumLongitude)
        
        return MGLCoordinateBounds(sw: sw, ne: ne)
    }
}
