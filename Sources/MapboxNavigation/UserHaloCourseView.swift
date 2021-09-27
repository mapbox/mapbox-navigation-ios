import UIKit
import CoreLocation

/**
 A view representing the user’s reduced accuracy location on screen.
 */
open class UserHaloCourseView: UIView, CourseUpdatable {

    /**
     Sets the inner fill color of the user halo.
     */
    @objc public dynamic var haloColor: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5) {
        didSet {
            haloView.haloColor = haloColor
        }
    }

    /**
     Sets the ring fill color of the circle around the user halo.
     */
    @objc public dynamic var haloRingColor: UIColor = #colorLiteral(red: 0.149, green: 0.239, blue: 0.341, alpha: 0.3) {
        didSet {
            haloView.haloRingColor = haloRingColor
        }
    }

    /**
     Sets the ring size by the radius of the user halo.
     */
    @objc public dynamic var haloRadius: Double = 100.0 {
        didSet {
            haloView.haloRadius = haloRadius
        }
    }
    
    /**
     Sets the halo ring border width.
     */
    @objc public dynamic var haloBorderWidth: Double = 5.0 {
        didSet {
            haloView.haloBorderWidth = haloBorderWidth
        }
    }

    var haloView: UserHaloStyleKitView!

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        isUserInteractionEnabled = false
        backgroundColor = .clear
        haloView = UserHaloStyleKitView(frame: bounds)
        haloView.backgroundColor = .clear
        addSubview(haloView)
    }
    
    /**
     Transforms the location of the user halo course view.
     */
    public func update(location: CLLocation, pitch: CGFloat, direction: CLLocationDegrees, animated: Bool, navigationCameraState: NavigationCameraState) {
        let duration: TimeInterval = animated ? 1 : 0
        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .curveLinear], animations: {
            // `UserHaloCourseView` pitch is changed only during transition to the overview mode.
            let pitch = CGFloat(navigationCameraState == .transitionToOverview ? 0.0 : CLLocationDegrees(pitch).toRadians())
            var transform = CATransform3DRotate(CATransform3DIdentity, pitch, 1.0, 0, 0)

            let isCameraFollowing = navigationCameraState == .following
            let scale = CGFloat(isCameraFollowing ? 1.0 : 0.5)
            transform = CATransform3DScale(transform, scale, scale, 1)
            transform.m34 = -1.0 / 1000 // (-1 / distance to projection plane)
            self.layer.sublayerTransform = transform
        }, completion: nil)
    }
}

class UserHaloStyleKitView: UIView {
    
    var haloColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5) {
        didSet {
            setNeedsDisplay()
        }
    }

    var haloRingColor = #colorLiteral(red: 0.149, green: 0.239, blue: 0.341, alpha: 0.3) {
        didSet {
            setNeedsDisplay()
        }
    }

    var haloRadius: Double = 100.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var haloBorderWidth: Double = 5.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawHaloView()
    }

    func drawHaloView() {
        let haloPath = UIBezierPath(arcCenter: center,
                                    radius: CGFloat(haloRadius),
                                    startAngle: 0,
                                    endAngle: 2.0 * CGFloat.pi,
                                    clockwise: true)
        let haloLayer = CAShapeLayer()
        haloLayer.frame = frame
        haloLayer.path = haloPath.cgPath
        haloLayer.fillColor = haloColor.cgColor
        haloLayer.strokeColor = haloRingColor.cgColor
        haloLayer.lineWidth = CGFloat(haloBorderWidth)
        layer.addSublayer(haloLayer)
    }
}
