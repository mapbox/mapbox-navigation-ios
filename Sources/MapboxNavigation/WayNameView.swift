import Foundation
import UIKit
import Turf
import MapboxMaps
import MapboxDirections

/**
 A label that is used to show a road name and a shield icon.
 */
@objc(MBWayNameLabel)
open class WayNameLabel: StylableLabel {
    var spriteRepository = SpriteRepository()
    var representation: VisualInstruction.Component.ImageRepresentation?
    
    @objc dynamic public var roadShieldBlackColor: UIColor = .roadShieldBlackColor
    @objc dynamic public var roadShieldBlueColor: UIColor = .roadShieldBlueColor
    @objc dynamic public var roadShieldGreenColor: UIColor = .roadShieldGreenColor
    @objc dynamic public var roadShieldRedColor: UIColor = .roadShieldRedColor
    @objc dynamic public var roadShieldWhiteColor: UIColor = .roadShieldWhiteColor
    @objc dynamic public var roadShieldYellowColor: UIColor = .roadShieldYellowColor
    @objc dynamic public var roadShieldOrangeColor: UIColor = .roadShieldOrangeColor
    @objc dynamic public var roadShieldDefaultColor: UIColor = .roadShieldDefaultColor
    
    // When the map style changes, update the sprite repository and the label.
    func updateStyle(styleURI: StyleURI?) {
        guard let styleURI = styleURI else { return }
        spriteRepository.updateRepository(styleURI: styleURI, representation: representation) { [weak self] in
            guard let self = self else { return }
            if let roadName = self.text {
                self.setUpWith(roadName: roadName)
            }
        }
    }
    
    func updateRoad(roadName: String, representation: VisualInstruction.Component.ImageRepresentation? = nil) {
        // When the imageRepresentation of road shield changes, update the sprite repository and the label.
        if representation != self.representation {
            spriteRepository.updateRepository(representation: representation) { [weak self] in
                guard let self = self else { return }
                self.representation = representation
                self.setUpWith(roadName: roadName)
            }
        }
        self.representation = representation
        setUpWith(roadName: roadName)
    }
    
    // Set up the `WayNameLabel` with the road name. Try to use the Mapbox designed shield first, if failed, fall back to use the legacy road shield icon.
    // If there's no valid shield image, display the road name only.
    private func setUpWith(roadName: String) {
        if let shield = representation?.shield {
            // For `us-state` shield, use the legacy shield first, then fall back to use the generic shield icon.
            // For non `us-state` shield, use the generic shield icon first, then fall back to use the legacy shield.
            if shield.name == "us-state",
               setAttributedText(roadName: roadName) {
                return
            } else if setAttributedText(roadName: roadName, shield: shield) {
                return
            }
        }
        
        if setAttributedText(roadName: roadName) {
            return
        }
        
        text = roadName
    }

    /**
     Fills contents of the `WayNameLabel` with the road name and legacy shield icon.
     
     - parameter roadName: The road name `String` that should be presented on the view.
     - returns: `true` if operation was successful, `false` otherwise.
     */
    @discardableResult
    private func setAttributedText(roadName: String) -> Bool {
        guard let shieldIcon = spriteRepository.getLegacyShield() else { return false }
        var currentShieldName: NSAttributedString?, currentRoadName: String?
        var didSetup = false

        let attachment = ShieldAttachment()
        let fontSize = frame.size.height / 2.5
        attachment.image = shieldIcon.withFontSize(font: UIFont.boldSystemFont(ofSize: fontSize),
                                                   size: frame.size)
        currentShieldName = NSAttributedString(attachment: attachment)

        if !roadName.isEmpty {
            currentRoadName = roadName
            text = roadName
            didSetup = true
        }

        if let compositeShieldImage = currentShieldName, let roadName = currentRoadName {
            let compositeShield = NSMutableAttributedString(string: " \(roadName)")
            compositeShield.insert(compositeShieldImage, at: 0)
            attributedText = compositeShield
            didSetup = true
        }
        return didSetup
    }
    
    /**
     Fills contents of the `WayNameLabel` with the road name and road shield.
     
     - parameter roadName: The road name `String` that should be presented on the view.
     - parameter shield: The  `ShieldRepresentation`object that represents the current road shield.
     - returns: `true` if operation was successful, `false` otherwise.
     */
    @discardableResult
    private func setAttributedText(roadName: String, shield: VisualInstruction.Component.ShieldRepresentation) -> Bool {
        guard let shieldIcon = spriteRepository.getShield(displayRef: shield.text, name: shield.name) else { return false }

        var currentShieldName: NSAttributedString?, currentRoadName: String?
        var didSetup = false
        
        currentShieldName = roadShieldAttributedText(for: shield.text, textColor: shield.textColor, image: shieldIcon)

        if !roadName.isEmpty {
            currentRoadName = roadName
            text = roadName
            didSetup = true
        }
        
        if let compositeShieldImage = currentShieldName, let roadName = currentRoadName {
            let compositeShield = NSMutableAttributedString(string: " \(roadName)")
            compositeShield.insert(compositeShieldImage, at: 0)
            attributedText = compositeShield
            didSetup = true
        }
        
        return didSetup
    }
    
    private func shieldColor(from shieldTextColor: String) -> UIColor {
        switch shieldTextColor {
        case "black":
            return roadShieldBlackColor
        case "blue":
            return roadShieldBlueColor
        case "green":
            return roadShieldGreenColor
        case "red":
            return roadShieldRedColor
        case "white":
            return roadShieldWhiteColor
        case "yellow":
            return roadShieldYellowColor
        case "orange":
            return roadShieldOrangeColor
        default:
            return roadShieldDefaultColor
        }
    }
    
    private func roadShieldAttributedText(for text: String,
                                          textColor: String,
                                          image: UIImage) -> NSAttributedString? {
        let attachment = ShieldAttachment()
        // To correctly scale size of the font its height is based on the label where it is shown.
        let fontSize = frame.size.height / 2.5
        let shieldColor = shieldColor(from: textColor)
        attachment.image = image.withCenteredText(text,
                                                  color: shieldColor,
                                                  font: UIFont.boldSystemFont(ofSize: fontSize),
                                                  size: frame.size)
        return NSAttributedString(attachment: attachment)
    }
    
}

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
}
