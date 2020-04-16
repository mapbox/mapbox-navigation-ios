import UIKit
import Turf
import Mapbox

let PuckSize: CGFloat = 45

/**
 A protocol that represents a `UIView` which tracks the user’s location and course on a `NavigationMapView`.
 */
public protocol CourseUpdatable where Self: UIView {
    /**
     Updates the view to reflect the given location and other camera properties.
     */
    func update(location: CLLocation, pitch: CGFloat, direction: CLLocationDegrees, animated: Bool, tracksUserCourse: Bool)
}

public extension CourseUpdatable {
    func update(location: CLLocation, pitch: CGFloat, direction: CLLocationDegrees, animated: Bool, tracksUserCourse: Bool) {
        applyDefaultUserPuckTransformation(location: location, pitch: pitch, direction: direction, animated: animated, tracksUserCourse: tracksUserCourse)
    }
    
    func applyDefaultUserPuckTransformation(location: CLLocation, pitch: CGFloat, direction: CLLocationDegrees, animated: Bool, tracksUserCourse: Bool) {
        let duration: TimeInterval = animated ? 1 : 0
        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .curveLinear], animations: {
            let angle = tracksUserCourse ? 0 : CLLocationDegrees(direction - location.course)
            self.layer.setAffineTransform(CGAffineTransform.identity.rotated(by: -CGFloat(angle.toRadians())))
            var transform = CATransform3DRotate(CATransform3DIdentity, CGFloat(CLLocationDegrees(pitch).toRadians()), 1.0, 0, 0)
            transform = CATransform3DScale(transform, tracksUserCourse ? 1 : 0.5, tracksUserCourse ? 1 : 0.5, 1)
            transform.m34 = -1.0 / 1000 // (-1 / distance to projection plane)
            self.layer.sublayerTransform = transform
        }, completion: nil)
    }
}

/**
 A view representing the user’s location on screen.
 */
public class UserPuckCourseView: UIView, CourseUpdatable {
    private var lastLocationUpdate: Date?
    private var staleTimer: Timer!
    
    /// Time interval tick at which Puck view is transitioning into 'stale' state
    public var staleRefreshInterval: TimeInterval = 1 {
        didSet {
            staleTimer.invalidate()
            initTimer()
        }
    }
    /// Time interval, after which Puck is considered 100% 'stale'
    public var staleInterval: TimeInterval = 60
    
    /**
     Transforms the location of the user puck.
     */
    public func update(location: CLLocation, pitch: CGFloat, direction: CLLocationDegrees, animated: Bool, tracksUserCourse: Bool) {
        let duration: TimeInterval = animated ? 1 : 0
        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .curveLinear], animations: {
            let angle = tracksUserCourse ? 0 : CLLocationDegrees(direction - location.course)
            self.puckView.layer.setAffineTransform(CGAffineTransform.identity.rotated(by: -CGFloat(angle.toRadians())))
            
            var transform = CATransform3DRotate(CATransform3DIdentity, CGFloat(CLLocationDegrees(pitch).toRadians()), 1.0, 0, 0)
            transform = CATransform3DScale(transform, tracksUserCourse ? 1 : 0.5, tracksUserCourse ? 1 : 0.5, 1)
            transform.m34 = -1.0 / 1000 // (-1 / distance to projection plane)
            self.layer.sublayerTransform = transform
        }, completion: nil)
    }
    
    // Sets the color on the user puck
    @objc public dynamic var puckColor: UIColor = #colorLiteral(red: 0.149, green: 0.239, blue: 0.341, alpha: 1) {
        didSet {
            puckView.puckColor = puckColor
        }
    }
    
    // Sets the color on the user puck in 'stale' state. Puck will gradually transition the color as long as location updates are missing
    @objc public dynamic var stalePuckColor: UIColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1) {
        didSet {
            puckView.stalePuckColor = stalePuckColor
        }
    }
    
    // Sets the fill color on the circle around the user puck
    @objc public dynamic var fillColor: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) {
        didSet {
            puckView.fillColor = fillColor
        }
    }
    
    // Sets the shadow color around the user puck
    @objc public dynamic var shadowColor: UIColor = #colorLiteral(red: 0.149, green: 0.239, blue: 0.341, alpha: 0.16) {
        didSet {
            puckView.shadowColor = shadowColor
        }
    }
    
    var puckView: UserPuckStyleKitView!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    deinit {
        staleTimer.invalidate()
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: nil)
    }
    
    func commonInit() {
        isUserInteractionEnabled = false
        backgroundColor = .clear
        puckView = UserPuckStyleKitView(frame: bounds)
        puckView.backgroundColor = .clear
        addSubview(puckView)
        
        initTimer()
        
        NotificationCenter.default.addObserver(self, selector: #selector(locationDidUpdate(_ :)), name: .routeControllerProgressDidChange, object: nil)
    }
    
    private func initTimer() {
        staleTimer = Timer(timeInterval: staleRefreshInterval,
                                target: self,
                                selector: #selector(refreshPuckStaleState),
                                userInfo: nil,
                                repeats: true)
        RunLoop.current.add(staleTimer, forMode: .common)
    }
    
    @objc func refreshPuckStaleState() {
        if let lastUpdate = lastLocationUpdate {
            let ratio = CGFloat(Date().timeIntervalSince(lastUpdate) / staleInterval)
            puckView.staleRatio = max(0.0, min(1.0, ratio))
        }
        else {
            puckView.staleRatio = 0.0
        }
    }
    
    @objc func locationDidUpdate(_ notification: NSNotification) {
        lastLocationUpdate = Date()
    }
}

class UserPuckStyleKitView: UIView {
    private typealias ColorComponents = (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat)
    
    var fillColor: UIColor = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var puckColor: UIColor = UIColor(red: 0.149, green: 0.239, blue: 0.341, alpha: 1.000) {
        didSet {
            puckColorComponents = colorComponents(puckColor)
            setNeedsDisplay()
        }
    }
    lazy private var puckColorComponents: ColorComponents! = colorComponents(puckColor)
    
    var stalePuckColor: UIColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1) {
        didSet {
            stalePuckColorComponents = colorComponents(stalePuckColor)
            setNeedsDisplay()
        }
    }
    lazy private var stalePuckColorComponents: ColorComponents! = colorComponents(stalePuckColor)
    
    var staleRatio: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var shadowColor: UIColor = UIColor(red: 0.149, green: 0.239, blue: 0.341, alpha: 0.160) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private func colorComponents(_ color: UIColor) -> ColorComponents {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        color.getHue(&hue,
                     saturation: &saturation,
                     brightness: &brightness,
                     alpha: &alpha)
        return (hue, saturation, brightness, alpha)
    }
    
    private func drawingPuckColor() -> UIColor
    {
        return UIColor(hue: puckColorComponents.hue + (stalePuckColorComponents.hue - puckColorComponents.hue) * staleRatio,
                       saturation: puckColorComponents.saturation + (stalePuckColorComponents.saturation - puckColorComponents.saturation) * staleRatio,
                       brightness: puckColorComponents.brightness + (stalePuckColorComponents.brightness - puckColorComponents.brightness) * staleRatio,
                       alpha: puckColorComponents.alpha + (stalePuckColorComponents.alpha - puckColorComponents.alpha) * staleRatio)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawNavigation_puck(fillColor: fillColor, puckColor: drawingPuckColor(), shadowColor: shadowColor, circleColor: fillColor)
    }
    
    func drawNavigation_puck(fillColor: UIColor = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000), puckColor: UIColor = UIColor(red: 0.149, green: 0.239, blue: 0.341, alpha: 1.000), shadowColor: UIColor = UIColor(red: 0.149, green: 0.239, blue: 0.341, alpha: 0.160), circleColor: UIColor = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)) {
        
        //// Canvas 2
        //// navigation_pluck
        //// Oval 7
        //// path0_fill Drawing
        let path0_fillPath = UIBezierPath(ovalIn: CGRect(x: 9, y: 9, width: 57, height: 57))
        fillColor.setFill()
        path0_fillPath.fill()
        
        //// Group 4
        //// path1_stroke_2x Drawing
        let path1_stroke_2xPath = UIBezierPath()
        path1_stroke_2xPath.move(to: CGPoint(x: 37.5, y: 75))
        path1_stroke_2xPath.addCurve(to: CGPoint(x: 75, y: 37.5), controlPoint1: CGPoint(x: 58.21, y: 75), controlPoint2: CGPoint(x: 75, y: 58.21))
        path1_stroke_2xPath.addLine(to: CGPoint(x: 57, y: 37.5))
        path1_stroke_2xPath.addCurve(to: CGPoint(x: 37.5, y: 57), controlPoint1: CGPoint(x: 57, y: 48.27), controlPoint2: CGPoint(x: 48.27, y: 57))
        path1_stroke_2xPath.addLine(to: CGPoint(x: 37.5, y: 75))
        path1_stroke_2xPath.close()
        path1_stroke_2xPath.move(to: CGPoint(x: 75, y: 37.5))
        path1_stroke_2xPath.addCurve(to: CGPoint(x: 37.5, y: 0), controlPoint1: CGPoint(x: 75, y: 16.79), controlPoint2: CGPoint(x: 58.21, y: 0))
        path1_stroke_2xPath.addLine(to: CGPoint(x: 37.5, y: 18))
        path1_stroke_2xPath.addCurve(to: CGPoint(x: 57, y: 37.5), controlPoint1: CGPoint(x: 48.27, y: 18), controlPoint2: CGPoint(x: 57, y: 26.73))
        path1_stroke_2xPath.addLine(to: CGPoint(x: 75, y: 37.5))
        path1_stroke_2xPath.close()
        path1_stroke_2xPath.move(to: CGPoint(x: 37.5, y: 0))
        path1_stroke_2xPath.addCurve(to: CGPoint(x: 0, y: 37.5), controlPoint1: CGPoint(x: 16.79, y: 0), controlPoint2: CGPoint(x: 0, y: 16.79))
        path1_stroke_2xPath.addLine(to: CGPoint(x: 18, y: 37.5))
        path1_stroke_2xPath.addCurve(to: CGPoint(x: 37.5, y: 18), controlPoint1: CGPoint(x: 18, y: 26.73), controlPoint2: CGPoint(x: 26.73, y: 18))
        path1_stroke_2xPath.addLine(to: CGPoint(x: 37.5, y: 0))
        path1_stroke_2xPath.close()
        path1_stroke_2xPath.move(to: CGPoint(x: 0, y: 37.5))
        path1_stroke_2xPath.addCurve(to: CGPoint(x: 37.5, y: 75), controlPoint1: CGPoint(x: 0, y: 58.21), controlPoint2: CGPoint(x: 16.79, y: 75))
        path1_stroke_2xPath.addLine(to: CGPoint(x: 37.5, y: 57))
        path1_stroke_2xPath.addCurve(to: CGPoint(x: 18, y: 37.5), controlPoint1: CGPoint(x: 26.73, y: 57), controlPoint2: CGPoint(x: 18, y: 48.27))
        path1_stroke_2xPath.addLine(to: CGPoint(x: 0, y: 37.5))
        path1_stroke_2xPath.close()
        shadowColor.setFill()
        path1_stroke_2xPath.fill()
        
        //// path0_fill 2 Drawing
        let path0_fill2Path = UIBezierPath(ovalIn: CGRect(x: 9, y: 9, width: 57, height: 57))
        circleColor.setFill()
        path0_fill2Path.fill()
        
        //// Page 1
        //// Fill 1
        //// path3_fill Drawing
        let path3_fillPath = UIBezierPath()
        path3_fillPath.move(to: CGPoint(x: 39.2, y: 28.46))
        path3_fillPath.addCurve(to: CGPoint(x: 38.02, y: 27.69), controlPoint1: CGPoint(x: 39, y: 27.99), controlPoint2: CGPoint(x: 38.54, y: 27.68))
        path3_fillPath.addCurve(to: CGPoint(x: 36.8, y: 28.49), controlPoint1: CGPoint(x: 37.5, y: 27.7), controlPoint2: CGPoint(x: 37.02, y: 28.01))
        path3_fillPath.addLine(to: CGPoint(x: 27.05, y: 45.83))
        path3_fillPath.addCurve(to: CGPoint(x: 27.28, y: 47.26), controlPoint1: CGPoint(x: 26.83, y: 46.32), controlPoint2: CGPoint(x: 26.92, y: 46.89))
        path3_fillPath.addCurve(to: CGPoint(x: 28.71, y: 47.54), controlPoint1: CGPoint(x: 27.65, y: 47.64), controlPoint2: CGPoint(x: 28.21, y: 47.75))
        path3_fillPath.addLine(to: CGPoint(x: 37.07, y: 44.03))
        path3_fillPath.addCurve(to: CGPoint(x: 38.06, y: 44.02), controlPoint1: CGPoint(x: 37.39, y: 43.89), controlPoint2: CGPoint(x: 37.75, y: 43.89))
        path3_fillPath.addLine(to: CGPoint(x: 46.26, y: 47.34))
        path3_fillPath.addCurve(to: CGPoint(x: 47.71, y: 47.03), controlPoint1: CGPoint(x: 46.75, y: 47.54), controlPoint2: CGPoint(x: 47.32, y: 47.42))
        path3_fillPath.addCurve(to: CGPoint(x: 48, y: 45.59), controlPoint1: CGPoint(x: 48.09, y: 46.64), controlPoint2: CGPoint(x: 48.2, y: 46.07))
        path3_fillPath.addLine(to: CGPoint(x: 39.2, y: 28.46))
        path3_fillPath.close()
        path3_fillPath.usesEvenOddFillRule = true
        puckColor.setFill()
        path3_fillPath.fill()
    }
}
