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
    public class var route: UIColor { get { return #colorLiteral(red:0.00, green:0.70, blue:0.99, alpha:1.0) } }
    public class var routeCoordinate: UIColor { get { return #colorLiteral(red: 0, green: 1, blue: 0.99, alpha: 0.3012764085) } }
    fileprivate class var rawLocation: UIColor { get { return #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1) } }
    fileprivate class var snappedLocation: UIColor { get { return #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1) } }
}

public protocol Plotter {
    var color: UIColor { get }
    var drawIndexesAsText: Bool { get }
    func draw(on plotter: NavigationPlotter)
}

public struct CoordinatePlotter: Plotter {
    public let coordinates: [CLLocationCoordinate2D]
    public let coordinateText: [String]?
    public let fontSize: CGFloat
    public let color: UIColor
    public let drawIndexesAsText: Bool
    
    public init(coordinates: [CLLocationCoordinate2D], coordinateText: [String]? = nil, fontSize: CGFloat = 9, color: UIColor, drawIndexesAsText: Bool) {
        self.coordinates = coordinates
        self.coordinateText = coordinateText
        self.fontSize = fontSize
        self.color = color
        self.drawIndexesAsText = drawIndexesAsText
    }
}

public struct LocationPlotter: Plotter {
    public let locations: [CLLocation]
    public let color: UIColor
    public let drawIndexesAsText: Bool
    
    public init(locations: [CLLocation], color: UIColor, drawIndexesAsText: Bool) {
        self.locations = locations
        self.color = color
        self.drawIndexesAsText = drawIndexesAsText
    }
}

public struct LinePlotter: Plotter {
    public let coordinates: [CLLocationCoordinate2D]
    public let color: UIColor
    public let lineWidth: CGFloat
    public let drawIndexesAsText: Bool
    
    public init(coordinates: [CLLocationCoordinate2D], color: UIColor, lineWidth: CGFloat, drawIndexesAsText: Bool) {
        self.coordinates = coordinates
        self.color = color
        self.lineWidth = lineWidth
        self.drawIndexesAsText = drawIndexesAsText
    }
}

public struct RoutePlotter: Plotter {
    public let route: Route
    public let color: UIColor
    public let lineWidth: CGFloat
    public let drawIndexesAsText: Bool
    public let drawDotIndicator: Bool
    public let drawTextIndicator: Bool
    
    public init(route: Route, color: UIColor = UIColor.route, lineWidth: CGFloat = 4, drawIndexesAsText: Bool = false, drawDotIndicator: Bool = true, drawTextIndicator: Bool = true) {
        self.route = route
        self.color = color
        self.lineWidth = lineWidth
        self.drawIndexesAsText = drawIndexesAsText
        self.drawDotIndicator = drawDotIndicator
        self.drawTextIndicator = drawTextIndicator
    }
}

public struct MatchPlotter: Plotter {
    public let match: Match
    public let color: UIColor
    public let lineWidth: CGFloat
    public let drawIndexesAsText: Bool
    public let drawDotIndicator: Bool
    public let drawTextIndicator: Bool
    
    public init(match: Match, color: UIColor = UIColor.route, lineWidth: CGFloat = 4, drawIndexesAsText: Bool = false, drawDotIndicator: Bool = true, drawTextIndicator: Bool = true) {
        self.match = match
        self.color = color
        self.lineWidth = lineWidth
        self.drawIndexesAsText = drawIndexesAsText
        self.drawDotIndicator = drawDotIndicator
        self.drawTextIndicator = drawTextIndicator
    }
}

extension RoutePlotter {
    public func draw(on plotter: NavigationPlotter) {
        plotter.drawLines(between: route.coordinates!, color: color, lineWidth: lineWidth, drawDotIndicator: drawDotIndicator, drawTextIndicator: drawTextIndicator)
    }
}

extension MatchPlotter {
    public func draw(on plotter: NavigationPlotter) {
        plotter.drawLines(between: match.coordinates!, color: color, lineWidth: lineWidth, drawDotIndicator: drawDotIndicator, drawTextIndicator: drawTextIndicator)
    }
}

extension CoordinatePlotter {
    public func draw(on plotter: NavigationPlotter) {
        for (i, coordinate) in coordinates.enumerated() {
            let position = plotter.mapView!.convert(coordinate, toPointTo: plotter)
            let centeredPosition = CGPoint(x: position.x - Constants.dotSize.width / 2,
                                           y: position.y - Constants.dotSize.height / 2)
            plotter.drawDot(at: centeredPosition, color: color)
            
            if drawIndexesAsText {
                plotter.drawText(at: centeredPosition, text: "\(i)")
            }
            
            if let coordinateText = coordinateText {
                let text = coordinateText[i]
                plotter.drawText(at: centeredPosition, text: text, fontSize: fontSize)
            }
        }
    }
}

extension LocationPlotter {
    public func draw(on plotter: NavigationPlotter) {
        for (i, location) in locations.enumerated() {
            let position = plotter.mapView!.convert(location.coordinate, toPointTo: plotter)
            let centeredPosition = CGPoint(x: position.x - Constants.dotSize.width / 2,
                                           y: position.y - Constants.dotSize.height / 2)
            plotter.drawDot(at: centeredPosition, color: color)
            plotter.drawCourseIndicator(at: centeredPosition, course: location.course)
            
            if drawIndexesAsText {
                plotter.drawText(at: centeredPosition, text: "\(i)")
            }
        }
    }
}

extension LinePlotter {
    public func draw(on plotter: NavigationPlotter) {
        plotter.drawLines(between: coordinates, color: color, lineWidth: lineWidth, drawDotIndicator: false, drawTextIndicator: false)
    }
}

public class NavigationPlotter: UIView {
    
    var mapView: NavigationMapView?
    var coordinateBounds: MGLCoordinateBounds?
    public var routePlotters: [RoutePlotter]? { didSet { setNeedsDisplay() } }
    public var matchPlotters: [MatchPlotter]? { didSet { setNeedsDisplay() } }
    public var coordinatePlotters: [CoordinatePlotter]? { didSet { setNeedsDisplay() } }
    public var locationPlotters: [LocationPlotter]? { didSet { setNeedsDisplay() } }
    public var linePlotters: [LinePlotter]? { didSet { setNeedsDisplay() } }
    
    func updateCoordinateBounds() {
        coordinateBounds = allBoundingCoordinates.bounds
        mapView = NavigationMapView(frame: bounds)
        let padding = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
        mapView?.setVisibleCoordinateBounds(coordinateBounds!, edgePadding: padding, animated: false)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var allBoundingCoordinates: [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()
        
        routePlotters?.forEach({ (plotter) in
            coordinates += plotter.route.coordinates!
        })
        
        matchPlotters?.forEach({ (plotter) in
            coordinates += plotter.match.coordinates!
        })
        
        coordinatePlotters?.forEach({ (plotter) in
            coordinates += plotter.coordinates
        })
        
        locationPlotters?.forEach({ (plotter) in
            coordinates += plotter.locations.map { $0.coordinate }
        })
        
        linePlotters?.forEach({ (plotter) in
            coordinates += plotter.coordinates
        })
        
        return coordinates
    }
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        updateCoordinateBounds()
        
        routePlotters?.forEach { $0.draw(on: self) }
        matchPlotters?.forEach { $0.draw(on: self) }
        linePlotters?.forEach { $0.draw(on: self) }
        coordinatePlotters?.forEach { $0.draw(on: self) }
        locationPlotters?.forEach { $0.draw(on: self) }
    }
    
    func drawLines(between coordinates: [CLLocationCoordinate2D]?, color: UIColor = UIColor.route, lineWidth: CGFloat = 4, drawDotIndicator: Bool = true, drawTextIndicator: Bool = true) {
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
        
        color.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
        
        for (i, coordinate) in coordinates.enumerated() {
            let position = mapView!.convert(coordinate, toPointTo: self)
            let centeredPosition = CGPoint(x: position.x - Constants.dotSize.width / 2,
                                           y: position.y - Constants.dotSize.height / 2)
            if drawDotIndicator {
                drawDot(at: centeredPosition, color: .routeCoordinate)
            }
            if drawTextIndicator {
                drawText(at: position, text: "\(i)")
            }
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
    
    fileprivate func drawText(at point: CGPoint, text: String, fontSize: CGFloat = 9) {
        let context = UIGraphicsGetCurrentContext()!
        let textRect = CGRect(origin: point, size: CGSize(width: 80, height: 20))
        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = .left
        
        #if swift(>=4.2)
            let attributes: [NSAttributedString.Key: Any]
        #else
            let attributes: [NSAttributedStringKey: Any]
        #endif
        
        attributes = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
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
        
        #if swift(>=4.2)
            let attributes: [NSAttributedString.Key: Any]
        #else
            let attributes: [NSAttributedStringKey: Any]
        #endif
        
        attributes = [
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
