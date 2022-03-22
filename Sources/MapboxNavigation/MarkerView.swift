import UIKit

// :nodoc:
@available(*, deprecated, message: "This class is no longer used.")
@objc(MBMarkerView)
public class MarkerView: UIView {
    
    // Sets the inner color on the pin.
    @objc public dynamic var innerColor: UIColor = .white {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // Sets the shadow color under the marker view.
    @objc public dynamic var shadowColor: UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // Sets the color on the marker view.
    @objc public dynamic var pinColor: UIColor = #colorLiteral(red: 0.1493228376, green: 0.2374534607, blue: 0.333029449, alpha: 1) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // Sets the stroke color on the marker view.
    @objc public dynamic var strokeColor: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override public var intrinsicContentSize: CGSize {
        return CGSize(width: 39, height: 51)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = .clear
    }
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        StyleKitMarker.drawMarker(innerColor: innerColor, shadowColor: shadowColor, pinColor: pinColor, strokeColor: strokeColor)
    }
}
