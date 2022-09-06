import UIKit
import MapboxMaps

/**
 `Style` is a convenient wrapper for styling the appearance of various interface components throughout the Navigation UI.
 
 Styles are applied globally using `UIAppearance`. You should call `Style.apply()` to apply the style to the `NavigationViewController`.
 */
@objc(MBStyle)
open class Style: NSObject {
    
    // MARK: - General styling properties
    
    /**
     Sets the tint color for guidance arrow, highlighted text, progress bar and more.
     */
    @objc public var tintColor: UIColor?
    
    /**
     Sets the status bar style.
     `UIViewControllerBasedStatusBarAppearance` must be set to NO for this property to have any effect.
     */
    public var statusBarStyle: UIStatusBarStyle?
    
    /**
     Sets the font family for all labels.
     */
    @objc public var fontFamily: String?
    
    /**
     Describes the situations in which the style should be used. By default, the style will be used during the daytime.
     */
    @objc public var styleType: StyleType = .day
    
    /**
     URL of the style to display on the map during turn-by-turn navigation.
     */
    @objc open var mapStyleURL = URL(string: StyleURI.navigationDay.rawValue)!
    
    /**
     URL of the style to display on the map when previewing a route, for example on CarPlay or your own route preview map.
     
     Defaults to same style as `mapStyleURL`.
     */
    @objc open var previewMapStyleURL = URL(string: StyleURI.navigationDay.rawValue)!
    
    var traitCollection: UITraitCollection = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceIdiom: .phone),
        UITraitCollection(userInterfaceIdiom: .pad),
    ])
    
    class var defaultBorderWidth: CGFloat {
        1 / UIScreen.main.scale
    }
    
    class var defaultCornerRadius: CGFloat {
        10.0
    }
    
    /**
     Applies the style for all changed properties.
     */
    @objc open func apply() { }
    
    @objc public required override init() { }
}
