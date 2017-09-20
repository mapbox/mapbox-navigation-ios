import UIKit

import Mapbox

let PuckSize: CGFloat = 45
let ArrowSize = PuckSize * 0.6

/**
 A view that represents the user’s location and course on a `NavigationMapView`.
 */
@objc(MBUserCourseView)
public protocol UserCourseView {
    /**
     Updates the view to reflect the given location and other camera properties.
     */
    func update(location: CLLocation, pitch: CGFloat, direction: CLLocationDegrees, animated: Bool)
}

class UserPuckCourseView: UIView, UserCourseView {
    
    var puckDot: CALayer?
    var puckArrow: CAShapeLayer?
    var location: CLLocation = CLLocation()
    var heading: CLHeading = CLHeading()
    
    var pitch: CLLocationDegrees = 0 {
        didSet {
            if oldValue != pitch {
                updatePitch()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bounds = CGRect(origin: .zero, size: CGSize(width: PuckSize, height: PuckSize))
    }
    
    func update(location: CLLocation, pitch: CGFloat, direction: CLLocationDegrees, animated: Bool) {
        drawPuck(location, pitch, direction)
        self.pitch = CLLocationDegrees(pitch)
    }
    
    func updatePitch() {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        let t = CATransform3DRotate(CATransform3DIdentity, CGFloat(pitch.toRadians()), 1, 0, 0)
        layer.sublayerTransform = t
        
        updateFaux3DEffect()
        
        CATransaction.commit()
    }
    
    func updateFaux3DEffect() {
        puckDot?.shadowOffset = CGSize(width: 0, height: CGFloat(fmaxf(Float(pitch.toRadians() * 10), 1)))
        puckDot?.shadowRadius = CGFloat(fmaxf(Float(pitch.toRadians()) * 5, 0.75))
    }
    
    func circleLayer(with size: CGSize) -> CALayer {
        let layer = CALayer()
        layer.bounds = CGRect(origin: .zero, size: size)
        layer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        layer.cornerRadius = size.width / 2
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        layer.drawsAsynchronously = true
        return layer
    }
    
    var puckArrowPath: UIBezierPath {
        let max = ArrowSize
        let path = UIBezierPath()
        path.move(to:       CGPoint(x: max * 0.5, y: 0))
        path.addLine(to:    CGPoint(x: max * 0.1, y: max))
        path.addLine(to:    CGPoint(x: max * 0.5, y: max * 0.65))
        path.addLine(to:    CGPoint(x: max * 0.9, y: max))
        path.addLine(to:    CGPoint(x: max * 0.5, y: 0))
        path.close()
        return path
    }
    
    func drawPuck(_ location: CLLocation,_ pitch: CGFloat, _ direction: CLLocationDegrees) {
        
        bounds = CGRect(origin: .zero, size: CGSize(width: PuckSize, height: PuckSize))
        
        if puckDot == nil {
            puckDot = circleLayer(with: CGSize(width: PuckSize, height: PuckSize))
            puckDot?.backgroundColor = UIColor.white.cgColor
            puckDot?.shadowColor = UIColor.black.cgColor
            puckDot?.shadowOpacity = 0.25
            puckDot?.shadowPath = UIBezierPath(ovalIn: puckDot!.bounds).cgPath
            layer.addSublayer(puckDot!)
            
            updateFaux3DEffect()
        }
        
        if puckArrow == nil {
            puckArrow = CAShapeLayer()
            puckArrow?.path = puckArrowPath.cgPath
            puckArrow?.fillColor = tintColor.cgColor
            puckArrow?.bounds = CGRect(origin: .zero, size: CGSize(width: ArrowSize, height: ArrowSize))
            puckArrow?.position = CGPoint(x: bounds.midX, y: bounds.midY)
            puckArrow?.shouldRasterize = true
            puckArrow?.rasterizationScale = UIScreen.main.scale
            puckArrow?.drawsAsynchronously = true
            layer.addSublayer(puckArrow!)
        }
        
        if location.course >= 0 {
            let angle = CLLocationDegrees(direction - location.course)
            puckArrow?.setAffineTransform(CGAffineTransform.identity.rotated(by: -CGFloat(angle.toRadians())))
        }
    }
}

class NewUserPuckCourseView: UIView, UserCourseView {
    
    var puckLayerView: UserPuckStyleKitView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        puckLayerView = UserPuckStyleKitView(frame: bounds)
        backgroundColor = .clear
        puckLayerView.backgroundColor = .clear
        addSubview(puckLayerView)
    }
    
    var shouldAnimateTransformations: Bool = false
    
    var location: CLLocation?
    
    var pitch: CLLocationDegrees = 0 {
        didSet {
            if oldValue != pitch {
                let newPitch = pitch
                UIView.animate(withDuration: 1, delay: 0, options: [.beginFromCurrentState, .curveLinear], animations: {
                    var transform = CATransform3DRotate(CATransform3DIdentity, CGFloat(CLLocationDegrees(newPitch).toRadians()), 1.0, 0, 0)
                    transform.m34 = -1.0 / 1000 // (-1 / distance to projection plane)
                    self.layer.sublayerTransform = transform
                }, completion: nil)
            }
        }
    }
    
    var direction: CLLocationDirection = 0 {
        didSet {
            if oldValue != direction {
                guard let location = location else { return }
                let angle = CLLocationDegrees(direction - location.course)
                UIView.animate(withDuration: 1, delay: 0, options: [.beginFromCurrentState, .curveLinear], animations: {
                    self.puckLayerView.layer.setAffineTransform(CGAffineTransform.identity.rotated(by: -CGFloat(angle.toRadians())))
                }, completion: nil)
            }
        }
    }
    
    func update(location: CLLocation, pitch: CGFloat, direction: CLLocationDegrees, animated: Bool) {
        self.location = location
        self.direction = direction
        self.pitch = CLLocationDegrees(pitch)
    }
}

class UserPuckStyleKitView: UIView {
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawNavigation_puck()
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
