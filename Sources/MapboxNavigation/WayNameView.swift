import Foundation
import UIKit
import Turf
import MapboxMaps

/**
 A label that is used to show a road name and a shield icon.
 */
@objc(MBWayNameLabel)
open class WayNameLabel: StylableLabel {}

/**
 A host view for `WayNameLabel` that shows a road name and a shield icon.
 
 `WayNameView` is hidden or shown depending on the road name information availability. In case if
 such information is not present, `WayNameView` is automatically hidden. If you'd like to completely
 hide `WayNameView` set `WayNameView.isHidden` property to `true`.
 */
@objc(MBWayNameView)
open class WayNameView: UIView {
    
    private static let textInsets = UIEdgeInsets(top: 3, left: 14, bottom: 3, right: 14)
    
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
    @objc dynamic public var borderColor: UIColor? {
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
    @objc dynamic public var borderWidth: CGFloat {
        get {
            layer.borderWidth
        }
        
        set {
            layer.borderWidth = newValue
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
        containerView.pinInSuperview(respectingMargins: false)
        
        containerView.addSubview(label)
        label.pinInSuperview(respectingMargins: true)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.cornerRadius = bounds.midY
    }
    
    /**
     Fills contents of the `WayNameLabel` with the road name and shield icon by extracting it from the
     `Turf.Feature` and `MapboxMaps.Style` objects (if it's valid and available).
     
     - parameter feature: `Turf.Feature` object, properties of which will be checked for the appropriate
     shield image related information.
     - parameter style: Style of the map view instance.
     - returns: `true` if operation was successful, `false` otherwise.
     */
    @discardableResult
    func setupWith(feature: Turf.Feature, using style: MapboxMaps.Style?) -> Bool {
        var currentShieldName: NSAttributedString?, currentRoadName: String?
        var didSetup = false
        
        if case let .string(ref) = feature.properties?["ref"],
           case let .string(shield) = feature.properties?["shield"],
           case let .number(reflen) = feature.properties?["reflen"] {
            let textColor = roadShieldTextColor(line: feature) ?? .black
            let imageName = "\(shield)-\(Int(reflen))"
            currentShieldName = roadShieldAttributedText(for: ref, textColor: textColor, style: style, imageName: imageName)
        }
        
        if case let .string(roadName) = feature.properties?["name"], !roadName.isEmpty {
            currentRoadName = roadName
            self.text = roadName
            didSetup = true
        }
        
        if let compositeShieldImage = currentShieldName, let roadName = currentRoadName {
            let compositeShield = NSMutableAttributedString(string: " \(roadName)")
            compositeShield.insert(compositeShieldImage, at: 0)
            self.attributedText = compositeShield
            didSetup = true
        }
        
        return didSetup
    }
    
    private func roadShieldTextColor(line: Turf.Feature) -> UIColor? {
        guard case let .string(shield) = line.properties?["shield"] else {
            return nil
        }
        
        // shield_text_color is present in Mapbox Streets source v8 but not v7.
        guard case let .string(shieldTextColor) = line.properties?["shield_text_color"] else {
            let currentShield = HighwayShield.RoadType(rawValue: shield)
            return currentShield?.textColor
        }
        
        switch shieldTextColor {
        case "black":
            return .black
        case "blue":
            return .blue
        case "white":
            return .white
        case "yellow":
            return .yellow
        case "orange":
            return .orange
        default:
            return .black
        }
    }
    
    private func roadShieldAttributedText(for text: String,
                                          textColor: UIColor,
                                          style: MapboxMaps.Style?,
                                          imageName: String) -> NSAttributedString? {
        guard let image = style?.image(withId: imageName) else { return nil }
        let attachment = ShieldAttachment()
        // To correctly scale size of the font its height is based on the label where it is shown.
        let fontSize = label.frame.size.height / 2.5
        attachment.image = image.withCenteredText(text,
                                                  color: textColor,
                                                  font: UIFont.boldSystemFont(ofSize: fontSize),
                                                  size: label.frame.size)
        return NSAttributedString(attachment: attachment)
    }
}
