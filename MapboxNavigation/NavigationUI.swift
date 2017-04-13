import UIKit
import MapboxDirections
import Mapbox

let MBSecondsBeforeResetTrackingMode:TimeInterval = 25.0

extension UIColor {
    fileprivate class var defaultTint: UIColor { get { return #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1) } }
    fileprivate class var defaultTintStroke: UIColor { get { return #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1) } }
    fileprivate class var defaultPrimaryText: UIColor { get { return #colorLiteral(red: 45.0/255.0, green: 45.0/255.0, blue: 45.0/255.0, alpha: 1) } }
    fileprivate class var defaultSecondaryText: UIColor { get { return #colorLiteral(red: 0.4509803922, green: 0.4509803922, blue: 0.4509803922, alpha: 1) } }
    fileprivate class var defaultLine: UIColor { get { return #colorLiteral(red: 0.7825912237, green: 0.7776457667, blue: 0.7863886952, alpha: 0.7) } }
}

/**
 `NavigationUI` lets you apply basic styling to some of
 the MapboxNavigation elements.
 */
@objc(MBNavigationUI)
public class NavigationUI: NSObject {
    public static let shared = NavigationUI()
    
    fileprivate var _tintColor: UIColor?
    fileprivate var _tintStrokeColor: UIColor?
    fileprivate var _primaryTextColor: UIColor?
    fileprivate var _secondaryTextColor: UIColor?
    fileprivate var _lineColor: UIColor?
    
    /// Used for guidance arrow, highlighted text and progress bars.
    public var tintColor: UIColor {
        get { return _tintColor ?? .defaultTint }
        set { _tintColor = newValue }
    }
    
    /// Used for guidance arrow.
    public var tintStrokeColor: UIColor {
        get { return _tintStrokeColor ?? .defaultTintStroke }
        set { _tintStrokeColor = newValue }
    }
    
    /// Used for titles and prioritized information.
    public var primaryTextColor: UIColor {
        get { return _primaryTextColor ?? .defaultPrimaryText }
        set { _primaryTextColor = newValue }
    }
    
    /// Used for subtitles, distances and accessory labels.
    public var secondaryTextColor: UIColor {
        get { return _secondaryTextColor ?? .defaultSecondaryText }
        set { _secondaryTextColor = newValue }
    }
    
    /// Used for separators in table views.
    public var lineColor: UIColor {
        get { return _lineColor ?? .defaultLine }
        set { _lineColor = newValue }
    }
}
