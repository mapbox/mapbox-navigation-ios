import UIKit

extension UIFont {
    
    var fontSizeMultiplier: CGFloat {
        get {
            switch UIApplication.shared.preferredContentSizeCategory {
            case UIContentSizeCategory.accessibilityExtraExtraExtraLarge: return 23 / 16
            case UIContentSizeCategory.accessibilityExtraExtraLarge: return 22 / 16
            case UIContentSizeCategory.accessibilityExtraLarge: return 21 / 16
            case UIContentSizeCategory.accessibilityLarge: return 20 / 16
            case UIContentSizeCategory.accessibilityMedium: return 19 / 16
            case UIContentSizeCategory.extraExtraExtraLarge: return 19 / 16
            case UIContentSizeCategory.extraExtraLarge: return 18 / 16
            case UIContentSizeCategory.extraLarge: return 17 / 16
            case UIContentSizeCategory.large: return 1
            case UIContentSizeCategory.medium: return 15 / 16
            case UIContentSizeCategory.small: return 14 / 16
            case UIContentSizeCategory.extraSmall: return 13 / 16
            default: return 1
            }
        }
    }
    
    /**
     Returns an adjusted font for the `preferredContentSizeCategory`.
     */
    @objc public var adjustedFont: UIFont {
        let font = with(multiplier: fontSizeMultiplier)
        return font
    }
    
    func with(multiplier: CGFloat) -> UIFont {
        let font = UIFont(descriptor: fontDescriptor, size: pointSize * fontSizeMultiplier)
        return font
    }
    
    func with(fontFamily: String?) -> UIFont {
        guard let fontFamily = fontFamily else { return self }
        let weight = (fontDescriptor.object(forKey: .traits) as! [String: Any])[UIFontDescriptor.TraitKey.weight.rawValue]
        let descriptor = UIFontDescriptor(name: fontName, size: pointSize).withFamily(fontFamily).addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
    
    func with(weight: CGFloat) -> UIFont {
        let font = UIFont(descriptor: fontDescriptor.addingAttributes([.traits: weight]), size: pointSize)
        return font
    }
}
