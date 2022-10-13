import Foundation
import UIKit
import Turf
import MapboxMaps
import MapboxDirections

/**
 A host view for `WayNameLabel` that shows a road name and a shield icon.
 
 `WayNameView` is hidden or shown depending on the road name information availability. In case if
 such information is not present, `WayNameView` is automatically hidden. If you'd like to completely
 hide `WayNameView` set `WayNameView.isHidden` property to `true`.
 */
@objc(MBWayNameView)
open class WayNameView: UIView {
    
    lazy var label: WayNameLabel = .forAutoLayout()
    
    /**
     A host view for the `WayNameLabel` instance that is used internally to show or hide
     `WayNameLabel` depending on the road name data availability.
     */
    lazy var containerView: UIView = .forAutoLayout()
    
    var text: String? {
        get {
            return label.text
        }
        set {
            label.text = newValue
        }
    }
    
    var attributedText: NSAttributedString? {
        get {
            return label.attributedText
        }
        set {
            label.attributedText = newValue
        }
    }
    
    open override var layer: CALayer {
        containerView.layer
    }
    
    /**
     The background color of the `WayNameView`.
     */
    @objc dynamic public override var backgroundColor: UIColor? {
        get {
            containerView.backgroundColor
        }
        
        set {
            containerView.backgroundColor = newValue
        }
    }
    
    /**
     The color of the `WayNameView`'s border.
     */
    @objc public dynamic var borderColor: UIColor? {
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
        
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    /**
     The width of the `WayNameView`'s border.
     */
    @objc public dynamic var borderWidth: CGFloat {
        get {
            layer.borderWidth
        }
        
        set {
            layer.borderWidth = newValue
        }
    }
    
    var _cornerRadius: CGFloat?
    
    /**
     The radius of the `WayNameView`'s corner. By default corner radius is set to half of
     `WayNameView`'s height.
     */
    @objc public dynamic var cornerRadius: CGFloat {
        get {
            layer.cornerRadius
        }
        
        set {
            _cornerRadius = newValue
            layer.cornerRadius = newValue
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        commonInit()
    }
    
    private func commonInit() {
        addSubview(containerView)
        containerView.pinInSuperview()
        
        containerView.addSubview(label)
        label.pinInSuperview(respectingMargins: true)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.layer.cornerRadius = _cornerRadius ?? bounds.midY
    }
}
