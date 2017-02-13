import UIKit
import MapboxDirections
import Mapbox

extension UIColor {
    fileprivate class var defaultTint: UIColor { get { return #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1) } }
    fileprivate class var defaultTintStroke: UIColor { get { return #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1) } }
    fileprivate class var defaultPrimaryText: UIColor { get { return #colorLiteral(red: 45.0/255.0, green: 45.0/255.0, blue: 45.0/255.0, alpha: 1) } }
    fileprivate class var defaultSecondaryText: UIColor { get { return #colorLiteral(red: 0.4509803922, green: 0.4509803922, blue: 0.4509803922, alpha: 1) } }
    fileprivate class var defaultLine: UIColor { get { return #colorLiteral(red: 151.0/255.0, green: 151.0/255.0, blue: 151.0/255.0, alpha: 0.6) } }
}

public class NavigationUI: NSObject {
    
    public static let shared = NavigationUI()
    
    override public class func initialize() {
        _ = UIStoryboard(name: "Navigation", bundle: Bundle.navigationUI)
    }
    
    fileprivate var _tintColor: UIColor?
    fileprivate var _tintStrokeColor: UIColor?
    fileprivate var _primaryTextColor: UIColor?
    fileprivate var _secondaryTextColor: UIColor?
    fileprivate var _lineColor: UIColor?
    
    public var tintColor: UIColor {
        get { return _tintColor ?? .defaultTint }
        set { _tintColor = newValue }
    }
    
    public var tintStrokeColor: UIColor {
        get { return _tintStrokeColor ?? .defaultTintStroke }
        set { _tintStrokeColor = newValue }
    }
    
    public var primaryTextColor: UIColor {
        get { return _primaryTextColor ?? .defaultPrimaryText }
        set { _primaryTextColor = newValue }
    }
    
    public var secondaryTextColor: UIColor {
        get { return _secondaryTextColor ?? .defaultSecondaryText }
        set { _secondaryTextColor = newValue }
    }
    
    public var lineColor: UIColor {
        get { return _lineColor ?? .defaultLine }
        set { _lineColor = newValue }
    }
    
    public class func instantiate(route: Route, directions: Directions) -> RouteViewController {
        let destination = MGLPointAnnotation()
        destination.coordinate = route.coordinates!.last!
        
        let storyboard = UIStoryboard(name: "Navigation", bundle: Bundle.navigationUI)
        let controller = storyboard.instantiateInitialViewController() as! RouteViewController
        
        controller.route = route
        controller.destination = destination
        controller.directions = directions
        
        return controller
    }
}
