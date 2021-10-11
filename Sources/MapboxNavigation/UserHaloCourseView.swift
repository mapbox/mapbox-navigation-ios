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
            haloLayer.fillColor = haloColor.cgColor
        }
    }

    /**
     Sets the ring fill color of the circle around the user halo.
     */
    @objc public dynamic var haloRingColor: UIColor = #colorLiteral(red: 0.149, green: 0.239, blue: 0.341, alpha: 0.3) {
        didSet {
            haloLayer.strokeColor = haloRingColor.cgColor
        }
    }

    /**
     Sets the ring size by the radius of the user halo.
     */
    @objc public dynamic var haloRadius: Double = 100.0 {
        didSet {
            updateHaloLayer()
        }
    }
    
    /**
     Sets the halo ring border width.
     */
    @objc public dynamic var haloBorderWidth: Double = 5.0 {
        didSet {
            haloLayer.lineWidth = CGFloat(haloBorderWidth)
        }
    }
    
    var haloLayer: CAShapeLayer!
    
    let haloLayerName = "halo_layer"

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
        updateHaloLayer()
    }
    
    /**
     Allows to update halo layer (if it's present) by removing previous one and adding new `CAShapeLayer`.
     */
    func updateHaloLayer() {
        let haloSublayers = layer.sublayers?.filter({ $0.name == haloLayerName })
        haloSublayers?.forEach {
            $0.removeFromSuperlayer()
        }
        
        let haloPath = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                                    radius: CGFloat(haloRadius),
                                    startAngle: 0,
                                    endAngle: 2.0 * CGFloat.pi,
                                    clockwise: true)
        haloLayer = CAShapeLayer()
        haloLayer.name = haloLayerName
        haloLayer.frame = bounds
        haloLayer.path = haloPath.cgPath
        haloLayer.fillColor = haloColor.cgColor
        haloLayer.strokeColor = haloRingColor.cgColor
        haloLayer.lineWidth = CGFloat(haloBorderWidth)
        layer.addSublayer(haloLayer)
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        haloLayer.fillColor = haloColor.cgColor
        haloLayer.strokeColor = haloRingColor.cgColor
    }
}
