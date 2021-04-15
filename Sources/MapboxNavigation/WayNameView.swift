import Foundation
import UIKit
import Turf
import MapboxMaps


extension WayNameView {
    
    /// Attempts to fill contents with road name and shield icon.
    ///
    /// This method attempts to extract the road name and shield image as well as styling information and tries to display it. Return result shows if it was a success.
    @discardableResult
    public func setupWith(roadFeature feature: Feature, using style: MapboxMaps.Style?) -> Bool {
        var currentShieldName: NSAttributedString?, currentRoadName: String?
        var didSetup = false
        
        if let ref = feature.properties?["ref"] as? String,
           let shield = feature.properties?["shield"] as? String,
           let reflen = feature.properties?["reflen"] as? Int {
            let textColor = roadShieldTextColor(line: feature) ?? .black
            let imageName = "\(shield)-\(reflen)"
            currentShieldName = roadShieldAttributedText(for: ref, textColor: textColor, style: style, imageName: imageName)
        }
        
        if let roadName = feature.properties?["name"] as? String {
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
    
    private func roadShieldTextColor(line: Feature) -> UIColor? {
        guard let shield = line.properties?["shield"] as? String else {
            return nil
        }
        
        // shield_text_color is present in Mapbox Streets source v8 but not v7.
        guard let shieldTextColor = line.properties?["shield_text_color"] as? String else {
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
        guard let image = style?.getStyleImage(with: imageName)?.cgImage() else { return nil }
        let attachment = ShieldAttachment()
        attachment.image = UIImage(cgImage: image.takeRetainedValue()).withCenteredText(text,
                                                                                        color: textColor,
                                                                                        font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize),
                                                                                        scale: UIScreen.main.scale)
        return NSAttributedString(attachment: attachment)
    }
}
