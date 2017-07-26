import UIKit

import Mapbox

let PuckSize: CGFloat = 45
let ArrowSize = PuckSize * 0.6

class UserCourseView: UIView {
    
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
        puckDot?.shadowColor = UIColor.black.cgColor
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
            puckDot?.shadowPath = UIBezierPath(ovalIn: puckDot!.bounds).cgPath
            layer.addSublayer(puckDot!)
        }
        
        if puckArrow == nil {
            puckArrow = CAShapeLayer()
            puckArrow?.path = puckArrowPath.cgPath
            puckArrow?.fillColor = UIColor.red.cgColor
            puckArrow?.bounds = CGRect(origin: .zero, size: CGSize(width: ArrowSize, height: ArrowSize))
            puckArrow?.position = CGPoint(x: bounds.midX, y: bounds.midY)
            puckArrow?.shouldRasterize = true
            puckArrow?.rasterizationScale = UIScreen.main.scale
            puckArrow?.drawsAsynchronously = true
            layer.addSublayer(puckArrow!)
        }
        
//        if location.course >= 0 {
//            let angle = CLLocationDegrees(direction - location.course)
//            puckArrow?.setAffineTransform(CGAffineTransform.identity.rotated(by: -CGFloat(angle.toRadians())))
//        }
    }
    
}
