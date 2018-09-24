import Foundation
import Turf
import Mapbox
import MapboxDirections
@testable import MapboxCoreNavigation
@testable import MapboxNavigation

fileprivate struct Constants {
    static let dotSize = CGSize(width: 15, height: 15)
}

extension UIColor {
    fileprivate class var route: UIColor { get { return #colorLiteral(red:0.00, green:0.70, blue:0.99, alpha:1.0) } }
    fileprivate class var routeCoordinate: UIColor { get { return #colorLiteral(red: 0, green: 1, blue: 0.99, alpha: 0.3012764085) } }
    fileprivate class var rawLocation: UIColor { get { return #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1) } }
    fileprivate class var snappedLocation: UIColor { get { return #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1) } }
}

protocol Plotter {
    var color: UIColor { get }
    var drawIndexesAsText: Bool { get }
    func draw(on routePlotter: RoutePlotter)
}

struct CoordinatePlotter: Plotter {
    let coordinates: [CLLocationCoordinate2D]
    let color: UIColor
    let drawIndexesAsText: Bool
}

struct LocationPlotter: Plotter {
    let locations: [CLLocation]
    let color: UIColor
    let drawIndexesAsText: Bool
}

extension CoordinatePlotter {
    func draw(on routePlotter: RoutePlotter) {
        for (i, coordinate) in coordinates.enumerated() {
            let position = routePlotter.mapView!.convert(coordinate, toPointTo: routePlotter)
            let centeredPosition = CGPoint(x: position.x - Constants.dotSize.width / 2,
                                           y: position.y - Constants.dotSize.height / 2)
            routePlotter.drawDot(at: centeredPosition, color: color)
            
            if drawIndexesAsText {
                routePlotter.drawText(at: centeredPosition, text: "\(i)")
            }
        }
    }
}

extension LocationPlotter {
    func draw(on routePlotter: RoutePlotter) {
        for (i, location) in locations.enumerated() {
            let position = routePlotter.mapView!.convert(location.coordinate, toPointTo: routePlotter)
            let centeredPosition = CGPoint(x: position.x - Constants.dotSize.width / 2,
                                           y: position.y - Constants.dotSize.height / 2)
            routePlotter.drawDot(at: centeredPosition, color: color)
            routePlotter.drawCourseIndicator(at: centeredPosition, course: location.course)
            
            if drawIndexesAsText {
                routePlotter.drawText(at: centeredPosition, text: "\(i)")
            }
        }
    }
}

class RoutePlotter: UIView {
    
    var mapView: MGLMapView?
    var coordinateBounds: MGLCoordinateBounds?
    var route: Route? { didSet { setNeedsDisplay() } }
    var match: Match? { didSet { setNeedsDisplay() } }
    var coordinatePlotters: [CoordinatePlotter]?
    var locationPlotters: [LocationPlotter]?
    
    func updateCoordinateBounds() {
        guard let coordinates = route?.coordinates ?? match?.coordinates else { return }
        coordinateBounds = coordinates.bounds
        mapView = MGLMapView(frame: bounds)
        let padding = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
        mapView?.setVisibleCoordinateBounds(coordinateBounds!, edgePadding: padding, animated: false)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        updateCoordinateBounds()
        drawLines(between: route?.coordinates)
        drawLines(between: match?.coordinates)
        coordinatePlotters?.forEach { $0.draw(on: self) }
        locationPlotters?.forEach { $0.draw(on: self) }
    }
    
    func drawLines(between coordinates: [CLLocationCoordinate2D]?) {
        guard let coordinates = coordinates else { return }
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
        
        for (i, coordinate) in coordinates.enumerated() {
            let position = mapView!.convert(coordinate, toPointTo: self)
            let centeredPosition = CGPoint(x: position.x - Constants.dotSize.width / 2,
                                           y: position.y - Constants.dotSize.height / 2)
            drawDot(at: centeredPosition, color: .routeCoordinate)
            drawText(at: position, text: "\(i)")
        }
    }
}

extension UIView {
    fileprivate func drawDot(at point: CGPoint, color: UIColor) {
        let path = UIBezierPath(ovalIn: CGRect(origin: point, size: Constants.dotSize))
        color.setFill()
        path.fill()
        UIColor.white.setStroke()
        path.lineWidth = 2
        path.stroke()
    }
    
    fileprivate func drawCourseIndicator(at point: CGPoint, course: CLLocationDirection) {
        let path = UIBezierPath()
        
        let angle = CGFloat(CLLocationDirection(270 - course).toRadians())
        
        let centerPoint = CGPoint(x: point.x + Constants.dotSize.midWidth,
                                  y: point.y + Constants.dotSize.midHeight)
        let startPoint = CGPoint(x: centerPoint.x + sin(angle - .pi / 2) * Constants.dotSize.midWidth,
                                 y: centerPoint.y + cos(angle - .pi / 2) * Constants.dotSize.midHeight)
        path.move(to: startPoint)
        path.addLine(to: CGPoint(x: startPoint.x + sin(angle - .pi / 2) * Constants.dotSize.midWidth,
                                 y: startPoint.y + cos(angle - .pi / 2) * Constants.dotSize.midHeight))
        
        UIColor.white.setStroke()
        path.lineWidth = 2
        path.stroke()
    }
    
    fileprivate func drawText(at point: CGPoint, text: String) {
        let context = UIGraphicsGetCurrentContext()!
        let textRect = CGRect(origin: point, size: CGSize(width: 50, height: 20))
        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = .left
        
        let attributes: [NSAttributedStringKey: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: UIColor.white,
            .paragraphStyle: textStyle,
            .strokeColor: UIColor.black,
            .strokeWidth: -1
        ]
        
        let boundingRect = text.boundingRect(with: CGSize(width: textRect.width, height: CGFloat.infinity),
                                     options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        
        context.saveGState()
        let rect = CGRect(x: point.x - boundingRect.midX + Constants.dotSize.width / 2,
                          y: point.y - boundingRect.midY + Constants.dotSize.height / 2,
                          width: boundingRect.width,
                          height: boundingRect.height)
        text.draw(in: rect, withAttributes: attributes)
        context.restoreGState()
    }
    
    fileprivate func drawCourseText(at point: CGPoint, course: CLLocationDirection) {
        let context = UIGraphicsGetCurrentContext()!
        let textRect = CGRect(origin: point, size: CGSize(width: 50, height: 20))
        let text = "\(Int(round(course)))"
        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = .left
        
        let attributes: [NSAttributedStringKey: Any] = [
            .font: UIFont.systemFont(ofSize: 7, weight: .medium),
            .foregroundColor: UIColor.white,
            .paragraphStyle: textStyle,
            .strokeColor: UIColor.black,
            .strokeWidth: -1
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

extension CGSize {
    var midWidth: CGFloat { return width / 2 }
    var midHeight: CGFloat { return height / 2 }
}
