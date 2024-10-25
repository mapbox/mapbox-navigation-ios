import MapboxMaps
import UIKit

@_spi(MapboxInternal)
extension UIColor {
    public class var defaultTintColor: UIColor { #colorLiteral(red: 0.1843137255, green: 0.4784313725, blue: 0.7764705882, alpha: 1) }

    public class var defaultRouteCasing: UIColor { .defaultTintColor }
    public class var defaultRouteLayer: UIColor { #colorLiteral(red: 0.337254902, green: 0.6588235294, blue: 0.9843137255, alpha: 1) }
    public class var defaultAlternateLine: UIColor { #colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1) }
    public class var defaultAlternateLineCasing: UIColor { #colorLiteral(red: 0.5019607843, green: 0.4980392157, blue: 0.5019607843, alpha: 1) }
    public class var defaultManeuverArrowStroke: UIColor { .defaultRouteLayer }
    public class var defaultManeuverArrow: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }

    public class var trafficUnknown: UIColor { defaultRouteLayer }
    public class var trafficLow: UIColor { defaultRouteLayer }
    public class var trafficModerate: UIColor { #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1) }
    public class var trafficHeavy: UIColor { #colorLiteral(red: 1, green: 0.3019607843, blue: 0.3019607843, alpha: 1) }
    public class var trafficSevere: UIColor { #colorLiteral(red: 0.5607843137, green: 0.1411764706, blue: 0.2784313725, alpha: 1) }

    public class var alternativeTrafficUnknown: UIColor { defaultAlternateLine }
    public class var alternativeTrafficLow: UIColor { defaultAlternateLine }
    public class var alternativeTrafficModerate: UIColor { #colorLiteral(red: 0.75, green: 0.63, blue: 0.53, alpha: 1.0) }
    public class var alternativeTrafficHeavy: UIColor { #colorLiteral(red: 0.71, green: 0.51, blue: 0.51, alpha: 1.0) }
    public class var alternativeTrafficSevere: UIColor { #colorLiteral(red: 0.71, green: 0.51, blue: 0.51, alpha: 1.0) }

    public class var defaultRouteRestrictedAreaColor: UIColor { #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) }

    public class var defaultRouteAnnotationColor: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
    public class var defaultSelectedRouteAnnotationColor: UIColor { #colorLiteral(red: 0.1882352941, green: 0.4470588235, blue: 0.9607843137, alpha: 1) }

    public class var defaultRouteAnnotationTextColor: UIColor { #colorLiteral(red: 0.01960784314, green: 0.02745098039, blue: 0.03921568627, alpha: 1) }
    public class var defaultSelectedRouteAnnotationTextColor: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }

    public class var defaultRouteAnnotationMoreTimeTextColor: UIColor { #colorLiteral(red: 0.9215686275, green: 0.1450980392, blue: 0.1647058824, alpha: 1) }
    public class var defaultRouteAnnotationLessTimeTextColor: UIColor { #colorLiteral(red: 0.03529411765, green: 0.6666666667, blue: 0.4549019608, alpha: 1) }

    public class var defaultWaypointColor: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
    public class var defaultWaypointStrokeColor: UIColor { #colorLiteral(red: 0.137254902, green: 0.1490196078, blue: 0.1764705882, alpha: 1) }
}
