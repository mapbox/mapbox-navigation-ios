import UIKit
import MapboxMaps

extension UIColor {

    class var defaultTintColor: UIColor { #colorLiteral(red: 0.1843137255, green: 0.4784313725, blue: 0.7764705882, alpha: 1) }
    class var defaultPrimaryTextColor: UIColor { #colorLiteral(red: 0.176, green: 0.176, blue: 0.176, alpha: 1) }
    class var defaultDarkAppearanceBackgroundColor: UIColor { #colorLiteral(red: 0.1493228376, green: 0.2374534607, blue: 0.333029449, alpha: 1) }
    class var defaultBorderColor: UIColor { #colorLiteral(red: 0.804, green: 0.816, blue: 0.816, alpha: 1) }
    class var defaultBackgroundColor: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
    
    class var defaultRouteCasing: UIColor { .defaultTintColor }
    class var defaultRouteLayer: UIColor { #colorLiteral(red: 0.337254902, green: 0.6588235294, blue: 0.9843137255, alpha: 1) }
    class var defaultAlternateLine: UIColor { #colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1) }
    class var defaultAlternateLineCasing: UIColor { #colorLiteral(red: 0.5019607843, green: 0.4980392157, blue: 0.5019607843, alpha: 1) }
    class var defaultTraversedRouteColor: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0) }
    class var defaultManeuverArrowStroke: UIColor { .defaultRouteLayer }
    class var defaultManeuverArrow: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
    
    class var defaultTurnArrowPrimary: UIColor { #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) }
    class var defaultTurnArrowSecondary: UIColor { #colorLiteral(red: 0.6196078431, green: 0.6196078431, blue: 0.6196078431, alpha: 1) }
    
    class var defaultTurnArrowPrimaryHighlighted: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
    class var defaultTurnArrowSecondaryHighlighted: UIColor { UIColor.white.withAlphaComponent(0.4) }
    
    class var defaultLaneArrowPrimary: UIColor { #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) }
    class var defaultLaneArrowSecondary: UIColor { #colorLiteral(red: 0.6196078431, green: 0.6196078431, blue: 0.6196078431, alpha: 1) }
    
    class var defaultLaneArrowPrimaryHighlighted: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
    class var defaultLaneArrowSecondaryHighlighted: UIColor { UIColor(white: 0.7, alpha: 1.0) }
    
    class var trafficUnknown: UIColor { defaultRouteLayer }
    class var trafficLow: UIColor { defaultRouteLayer }
    class var trafficModerate: UIColor { #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1) }
    class var trafficHeavy: UIColor { #colorLiteral(red: 1, green: 0.3019607843, blue: 0.3019607843, alpha: 1) }
    class var trafficSevere: UIColor { #colorLiteral(red: 0.5607843137, green: 0.1411764706, blue: 0.2784313725, alpha: 1) }
    
    class var alternativeTrafficUnknown: UIColor { defaultAlternateLine }
    class var alternativeTrafficLow: UIColor { defaultAlternateLine }
    class var alternativeTrafficModerate: UIColor { #colorLiteral(red: 0.75, green: 0.63, blue: 0.53, alpha: 1.0) }
    class var alternativeTrafficHeavy: UIColor { #colorLiteral(red: 0.71, green: 0.51, blue: 0.51, alpha: 1.0) }
    class var alternativeTrafficSevere: UIColor { #colorLiteral(red: 0.71, green: 0.51, blue: 0.51, alpha: 1.0) }
    class var defaultBuildingColor: UIColor { #colorLiteral(red: 0.9833194452, green: 0.9843137255, blue: 0.9331936657, alpha: 0.8019049658) }
    class var defaultBuildingHighlightColor: UIColor { #colorLiteral(red: 0.337254902, green: 0.6588235294, blue: 0.9843137255, alpha: 0.949406036) }
    
    class var defaultRouteRestrictedAreaColor: UIColor { #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) }

    class var routeDurationAnnotationColor: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
    class var selectedRouteDurationAnnotationColor: UIColor { #colorLiteral(red: 0.337254902, green: 0.6588235294, blue: 0.9843137255, alpha: 1) }

    class var routeDurationAnnotationTextColor: UIColor { #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) }
    class var selectedRouteDurationAnnotationTextColor: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
    
    class var roadShieldDefaultColor: UIColor { #colorLiteral(red: 0.11, green: 0.11, blue: 0.15, alpha: 1) }
    class var roadShieldBlackColor: UIColor { roadShieldDefaultColor }
    class var roadShieldBlueColor: UIColor { #colorLiteral(red: 0.28, green: 0.36, blue: 0.8, alpha: 1) }
    class var roadShieldGreenColor: UIColor { #colorLiteral(red: 0.1, green: 0.64, blue: 0.28, alpha: 1) }
    class var roadShieldRedColor: UIColor { #colorLiteral(red: 0.95, green: 0.23, blue: 0.23, alpha: 1) }
    class var roadShieldWhiteColor: UIColor { #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) }
    class var roadShieldYellowColor: UIColor { #colorLiteral(red: 1.0, green: 0.9, blue: 0.4, alpha: 1) }
    class var roadShieldOrangeColor: UIColor { #colorLiteral(red: 1, green: 0.65, blue: 0, alpha: 1) }
    
    /**
     Returns `UIImage` representation of a `UIColor`.
     
     - parameter size: optional size of `UIImage`. If not provided empty image will be returned.
     */
    func image(_ size: CGSize = .zero) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    /**
     Convenience initializer, which allows to convert `StyleColor` to `UIColor`. This initializer
     is primarily used while retrieving color information from `LineLayer`.
     
     - parameter styleColor: Color, defined by the Mapbox Style Specification.
     */
    convenience init(_ styleColor: StyleColor) {
        self.init(red: CGFloat(styleColor.red / 255.0),
                  green: CGFloat(styleColor.green / 255.0),
                  blue: CGFloat(styleColor.blue / 255.0),
                  alpha: CGFloat(styleColor.alpha))
    }
    
    /**
     Returns hex representation of a `UIColor`.
     */
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        return String(format:"#%06x", rgb)
    }
}
