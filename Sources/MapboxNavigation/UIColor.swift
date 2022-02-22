import UIKit

extension UIColor {
    
    class var defaultTint: UIColor { get { return #colorLiteral(red: 0.1843137255, green: 0.4784313725, blue: 0.7764705882, alpha: 1) } }
    class var defaultTintStroke: UIColor { get { return #colorLiteral(red: 0.1843137255, green: 0.4784313725, blue: 0.7764705882, alpha: 1) } }
    class var defaultPrimaryText: UIColor { get { return #colorLiteral(red: 0.176470588, green: 0.176470588, blue: 0.176470588, alpha: 1) } }
    
    class var defaultRouteCasing: UIColor { get { return .defaultTintStroke } }
    class var defaultRouteLayer: UIColor { get { return #colorLiteral(red: 0.337254902, green: 0.6588235294, blue: 0.9843137255, alpha: 1) } }
    class var defaultAlternateLine: UIColor { get { return #colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1) } }
    class var defaultAlternateLineCasing: UIColor { get { return #colorLiteral(red: 0.5019607843, green: 0.4980392157, blue: 0.5019607843, alpha: 1) } }
    class var defaultTraversedRouteColor: UIColor { get { return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0) } }
    class var defaultManeuverArrowStroke: UIColor { get { return .defaultRouteLayer } }
    class var defaultManeuverArrow: UIColor { get { return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) } }
    
    class var defaultTurnArrowPrimary: UIColor { get { return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) } }
    class var defaultTurnArrowPrimaryHighlighted: UIColor { get { return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) } }
    class var defaultTurnArrowSecondary: UIColor { get { return #colorLiteral(red: 0.6196078431, green: 0.6196078431, blue: 0.6196078431, alpha: 1) } }
    class var defaultTurnArrowSecondaryHighlighted: UIColor { get { return UIColor.white.withAlphaComponent(0.4) } }
    
    class var defaultLaneArrowPrimary: UIColor { get { return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) } }
    class var defaultLaneArrowSecondary: UIColor { get { return #colorLiteral(red: 0.6196078431, green: 0.6196078431, blue: 0.6196078431, alpha: 1) } }
    class var defaultLaneArrowPrimaryHighlighted: UIColor { get { return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) } }
    class var defaultLaneArrowSecondaryHighlighted: UIColor { get { return UIColor(white: 0.7, alpha: 1.0) } }
    
    class var defaultLaneArrowPrimaryCarPlay: UIColor { get { return #colorLiteral(red: 0.7649999857, green: 0.7649999857, blue: 0.7570000291, alpha: 1) } }
    class var defaultLaneArrowSecondaryCarPlay: UIColor { get { return #colorLiteral(red: 0.4198532104, green: 0.4398920536, blue: 0.4437610507, alpha: 1) } }
    
    class var trafficUnknown: UIColor { get { return defaultRouteLayer } }
    class var trafficLow: UIColor { get { return defaultRouteLayer } }
    class var trafficModerate: UIColor { get { return #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1) } }
    class var trafficHeavy: UIColor { get { return #colorLiteral(red: 1, green: 0.3019607843, blue: 0.3019607843, alpha: 1) } }
    class var trafficSevere: UIColor { get { return #colorLiteral(red: 0.5607843137, green: 0.1411764706, blue: 0.2784313725, alpha: 1) } }
    
    class var alternativeTrafficUnknown: UIColor { get { return defaultAlternateLine } }
    class var alternativeTrafficLow: UIColor { get { return defaultAlternateLine } }
    class var alternativeTrafficModerate: UIColor { get { return #colorLiteral(red: 0.75, green: 0.63, blue: 0.53, alpha: 1.0) } }
    class var alternativeTrafficHeavy: UIColor { get { return #colorLiteral(red: 0.71, green: 0.51, blue: 0.51, alpha: 1.0) } }
    class var alternativeTrafficSevere: UIColor { get { return #colorLiteral(red: 0.71, green: 0.51, blue: 0.51, alpha: 1.0) } }
    class var defaultBuildingColor: UIColor { get { return #colorLiteral(red: 0.9833194452, green: 0.9843137255, blue: 0.9331936657, alpha: 0.8019049658) } }
    class var defaultBuildingHighlightColor: UIColor { get { return #colorLiteral(red: 0.337254902, green: 0.6588235294, blue: 0.9843137255, alpha: 0.949406036) } }
    
    class var defaultRouteRestrictedAreaColor: UIColor { get { return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)} }
    
    class var routeDurationAnnotationColor: UIColor { get { return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) } }
    class var selectedRouteDurationAnnotationColor: UIColor { get { return #colorLiteral(red: 0.337254902, green: 0.6588235294, blue: 0.9843137255, alpha: 1) } }
    
    class var routeDurationAnnotationTextColor: UIColor { get { return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) } }
    class var selectedRouteDurationAnnotationTextColor: UIColor { get { return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) } }
    
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
}
