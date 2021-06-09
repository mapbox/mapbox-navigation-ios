import UIKit
import CoreLocation

/**
 A view representing the user’s reduced accuracy location on screen.
 */
open class UserHaloCourseView: UIView, CourseUpdatable {
    private var lastLocationUpdate: Date?

    // Sets the inner fill color of the user halo
    @objc public dynamic var haloColor: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5) {
        didSet {
            haloView.haloColor = haloColor
        }
    }

    // Sets the ring fill color of the circle around the user halo
    @objc public dynamic var haloRingColor: UIColor = #colorLiteral(red: 0.149, green: 0.239, blue: 0.341, alpha: 0.3) {
        didSet {
            haloView.haloRingColor = haloRingColor
        }
    }

    // Sets the ring size by the radius of the user halo
    @objc public dynamic var haloRadius: Double = 100.0 {
        didSet {
            haloView.haloRadius = haloRadius
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

    @objc func locationDidUpdate(_ notification: NSNotification) {
        lastLocationUpdate = Date()
    }
}

class UserHaloStyleKitView: UIView {
    var haloColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)  {
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

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawHaloView()
    }

    func drawHaloView() {
        let borderWidth = 5.0
        let haloPath = UIBezierPath(arcCenter: center, radius: CGFloat(haloRadius), startAngle: 0, endAngle: 2.0 * CGFloat.pi, clockwise: true)
        let haloLayer = CAShapeLayer()
        
        haloLayer.path = haloPath.cgPath
        haloLayer.fillColor = haloColor.cgColor
        haloLayer.strokeColor = haloRingColor.cgColor
        haloLayer.lineWidth = CGFloat(borderWidth)
        haloLayer.borderWidth = CGFloat(borderWidth)
        layer.addSublayer(haloLayer)
    }
}
