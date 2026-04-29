import MapboxMaps
import UIKit

extension UIColor {
    class var defaultTintColor: UIColor { #colorLiteral(red: 0.1843137255, green: 0.4784313725, blue: 0.7764705882, alpha: 1) }
    class var defaultPrimaryTextColor: UIColor { #colorLiteral(red: 0.176, green: 0.176, blue: 0.176, alpha: 1) }
    class var defaultDarkAppearanceBackgroundColor: UIColor { #colorLiteral(red: 0.1493228376, green: 0.2374534607, blue: 0.333029449, alpha: 1) }
    class var defaultBorderColor: UIColor { #colorLiteral(red: 0.804, green: 0.816, blue: 0.816, alpha: 1) }
    class var defaultBackgroundColor: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }

    class var defaultTurnArrowPrimary: UIColor { #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) }
    class var defaultTurnArrowSecondary: UIColor { #colorLiteral(red: 0.6196078431, green: 0.6196078431, blue: 0.6196078431, alpha: 1) }

    class var defaultTurnArrowPrimaryHighlighted: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
    class var defaultTurnArrowSecondaryHighlighted: UIColor { UIColor.white.withAlphaComponent(0.4) }

    class var defaultLaneArrowPrimary: UIColor { #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) }
    class var defaultLaneArrowSecondary: UIColor { #colorLiteral(red: 0.6196078431, green: 0.6196078431, blue: 0.6196078431, alpha: 1) }

    class var defaultLaneArrowPrimaryHighlighted: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
    class var defaultLaneArrowSecondaryHighlighted: UIColor { UIColor(white: 0.7, alpha: 1.0) }

    class var roadShieldDefaultColor: UIColor { #colorLiteral(red: 0.11, green: 0.11, blue: 0.15, alpha: 1) }
    class var roadShieldBlackColor: UIColor { roadShieldDefaultColor }
    class var roadShieldBlueColor: UIColor { #colorLiteral(red: 0.28, green: 0.36, blue: 0.8, alpha: 1) }
    class var roadShieldGreenColor: UIColor { #colorLiteral(red: 0.1, green: 0.64, blue: 0.28, alpha: 1) }
    class var roadShieldRedColor: UIColor { #colorLiteral(red: 0.95, green: 0.23, blue: 0.23, alpha: 1) }
    class var roadShieldWhiteColor: UIColor { #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) }
    class var roadShieldYellowColor: UIColor { #colorLiteral(red: 1.0, green: 0.9, blue: 0.4, alpha: 1) }
    class var roadShieldOrangeColor: UIColor { #colorLiteral(red: 1, green: 0.65, blue: 0, alpha: 1) }

    /// Returns `UIImage` representation of a `UIColor`.
    ///
    /// - Parameter size: optional size of `UIImage`. If not provided empty image will be returned.
    func image(_ size: CGSize = .zero) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
