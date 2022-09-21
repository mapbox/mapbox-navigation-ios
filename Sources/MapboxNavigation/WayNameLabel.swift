import UIKit
import MapboxMaps
import MapboxDirections

/**
 A label that is used to show a road name and a shield icon.
 */
@objc(MBWayNameLabel)
open class WayNameLabel: StylableLabel {
    
    var spriteRepository: SpriteRepository = .shared
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
    func updateStyle(styleURI: StyleURI?, idiom: UIUserInterfaceIdiom = .phone) {
        spriteRepository.updateStyle(styleURI: styleURI, idiom: idiom) { [weak self] _ in
            guard let self = self, let roadName = self.text else { return }
            
            self.setup(with: roadName, idiom: idiom)
        }
    }
    
    func updateRoad(roadName: String,
                    representation: VisualInstruction.Component.ImageRepresentation? = nil,
                    idiom: UIUserInterfaceIdiom = .phone) {
        // When the imageRepresentation of road shield changes, update the sprite repository and the label.
        if representation != self.representation {
            spriteRepository.updateRepresentation(for: representation, idiom: idiom) { [weak self] _ in
                guard let self = self else { return }
                self.representation = representation
                self.setup(with: roadName, idiom: idiom)
            }
        }
        setup(with: roadName, idiom: idiom)
    }
    
    /**
     Set up the `WayNameLabel` with the road name. Try to use the Mapbox designed shield image first,
     if failed, fall back to use the legacy road shield icon.
     
     If there's no valid shield images, only road name is displayed.
     
     - parameter roadName: Name of the road, that is going to be displayed inside `WayNameLabel`.
     - parameter idiom: The `UIUserInterfaceIdiom` that the `WayNameLabel` is going to be displayed in.
     */
    private func setup(with roadName: String, idiom: UIUserInterfaceIdiom) {
        let shieldRepresentation = representation?.shield
        let legacyRoadShieldImage = spriteRepository.getLegacyShield(with: representation)
        
        // For US state road, use the legacy shield first, then fall back to use the generic shield icon.
        // The shield name for US state road is `circle-white` in Streets source v8 style.
        if let shieldRepresentation = shieldRepresentation,
           shieldRepresentation.name == "circle-white",
           let legacyRoadShieldImage = legacyRoadShieldImage {
            setAttributedText(roadName: roadName,
                              roadShieldImage: legacyRoadShieldImage)
            
            return
        }
        
        // For non US state road, use the generic shield icon first, then fall back to use the legacy shield.
        if let roadShieldImage = spriteRepository.roadShieldImage(from: shieldRepresentation, idiom: idiom) {
            setAttributedText(roadName: roadName,
                              roadShieldImage: roadShieldImage,
                              roadShieldText: shieldRepresentation?.text,
                              roadShieldTextColor: shieldRepresentation?.textColor)
            
            return
        }
        
        // In case if legacy shield icon is available - use it.
        if let legacyRoadShieldImage = legacyRoadShieldImage {
            setAttributedText(roadName: roadName,
                              roadShieldImage: legacyRoadShieldImage)
            
            return
        }
        
        // In case if neither generic nor legacy shield images are available - show only road name.
        text = roadName
    }
    
    private func setAttributedText(roadName: String,
                                   roadShieldImage: UIImage,
                                   roadShieldText: String? = nil,
                                   roadShieldTextColor: String? = nil) {
        let roadShieldAttributedString = roadShield(from: roadShieldImage,
                                                    text: roadShieldText,
                                                    textColor: roadShieldTextColor)
        
        let roadShieldAndNameAttributedString = NSMutableAttributedString()
        // Road shield image is always drawn in front of the road name.
        roadShieldAndNameAttributedString.append(roadShieldAttributedString)
        roadShieldAndNameAttributedString.append(NSAttributedString(string: " \(roadName)"))
        attributedText = roadShieldAndNameAttributedString
    }
    
    private func roadShield(from image: UIImage,
                            text: String? = nil,
                            textColor: String? = nil) -> NSAttributedString {
        let attachment = ShieldAttachment()
        // Shield attachment should use similar font that is currently used in `WayNameLabel`.
        attachment.font = font
        // To correctly scale size of the font its height is based on the label where it is shown.
        let fontSize = frame.size.height / 2.5
        
        // In case if `text` and `textColor` are valid - generate default road shield image, if not -
        // generate legacy road shield image.
        let roadShieldImage: UIImage
        if let text = text,
           let textColor = textColor {
            let shieldColor = shieldColor(from: textColor)
            roadShieldImage = image.withCenteredText(text,
                                                     color: shieldColor,
                                                     font: UIFont.boldSystemFont(ofSize: fontSize),
                                                     size: frame.size)
        } else {
            roadShieldImage = image.withFontSize(font: UIFont.boldSystemFont(ofSize: fontSize),
                                                 size: frame.size)
        }
        
        attachment.image = roadShieldImage
        
        return NSAttributedString(attachment: attachment)
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
}
