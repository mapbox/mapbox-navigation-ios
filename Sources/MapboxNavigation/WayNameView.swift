import Foundation
import UIKit
import Turf
import MapboxMaps

/// :nodoc:
@objc(MBWayNameLabel)
open class WayNameLabel: StylableLabel {}

/// :nodoc:
@objc(MBWayNameView)
open class WayNameView: UIView {
    private static let textInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
    
    lazy var label: WayNameLabel = .forAutoLayout()
    
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
    
    @objc dynamic public var borderColor: UIColor? {
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        addSubview(label)
        layoutMargins = WayNameView.textInsets
        label.pinInSuperview(respectingMargins: true)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.midY
    }
    
    /// Attempts to fill contents with road name and shield icon.
    ///
    /// This method attempts to extract the road name and shield image as well as styling information and tries to display it. Return result shows if it was a success.
    @discardableResult
    func setupWith(feature: MapboxCommon.Feature, using style: MapboxMaps.Style?) -> Bool {
        var currentShieldName: NSAttributedString?, currentRoadName: String?
        var didSetup = false
        
        if let ref = feature.properties["ref"] as? String,
           let shield = feature.properties["shield"] as? String,
           let reflen = feature.properties["reflen"] as? Int {
            let textColor = roadShieldTextColor(line: feature) ?? .black
            let imageName = "\(shield)-\(reflen)"
            currentShieldName = roadShieldAttributedText(for: ref, textColor: textColor, style: style, imageName: imageName)
        }
        
        if let roadName = feature.properties["name"] as? String, !roadName.isEmpty {
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
    
    private func roadShieldTextColor(line: MapboxCommon.Feature) -> UIColor? {
        guard let shield = line.properties["shield"] as? String else {
            return nil
        }
        
        // shield_text_color is present in Mapbox Streets source v8 but not v7.
        guard let shieldTextColor = line.properties["shield_text_color"] as? String else {
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
    
    private func roadShieldAttributedText(for text: String, textColor: UIColor, style: MapboxMaps.Style?, imageName: String) -> NSAttributedString? {
        guard let image = style?.image(withId: imageName) else { return nil }
        let attachment = ShieldAttachment()
        attachment.image = image.withCenteredText(text,
                                                  color: textColor,
                                                  font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize),
                                                  scale: UIScreen.main.scale)
        return NSAttributedString(attachment: attachment)
    }
}
