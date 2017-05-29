import UIKit

fileprivate extension CGFloat {
    fileprivate static var defaultManeuverViewHeight: CGFloat = 115
}

extension UIColor {
    class var defaultRouteCasing: UIColor { return .defaultTintStroke }
    class var defaultRouteLayer: UIColor { return UIColor.defaultTintStroke.withAlphaComponent(0.6) }
    class var defaultArrowStroke: UIColor { return .defaultTint }
}

fileprivate extension UIColor {
    // General styling
    fileprivate class var defaultTint: UIColor { return #colorLiteral(red: 0.1490196078, green: 0.2392156863, blue: 0.3411764706, alpha: 1) }
    fileprivate class var defaultTintStroke: UIColor { return #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1) }
    fileprivate class var defaultPrimaryText: UIColor { return #colorLiteral(red: 45.0/255.0, green: 45.0/255.0, blue: 45.0/255.0, alpha: 1) }
    fileprivate class var defaultSecondaryText: UIColor { return #colorLiteral(red: 0.4509803922, green: 0.4509803922, blue: 0.4509803922, alpha: 1) }
    fileprivate class var defaultLine: UIColor { return #colorLiteral(red: 0.2470588235, green: 0.3568627451, blue: 0.4823529412, alpha: 0.16) }
    
    // Maneuver view (Page view)
    fileprivate class var defaultManeuverViewBackground: UIColor { return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
    
    // Table view (Drawer)
    fileprivate class var defaultHeaderBackground: UIColor { return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
    fileprivate class var defaultHeaderTitleLabel: UIColor { return .defaultTint }
    fileprivate class var defaultHeaderSubtitleLabel: UIColor { return UIColor.defaultTint.withAlphaComponent(0.62) }
}

fileprivate extension UIFont {
    // General styling
    fileprivate class var defaultPrimaryText: UIFont { return UIFont.systemFont(ofSize: 16) }
    fileprivate class var defaultSecondaryText: UIFont { return UIFont.systemFont(ofSize: 16) }
    fileprivate class var defaultCellTitleLabel: UIFont { return UIFont.systemFont(ofSize: 28, weight: UIFontWeightMedium) }
    
    // Table view (drawer)
    fileprivate class var defaultHeaderTitleLabel: UIFont { return UIFont.preferredFont(forTextStyle: .headline) }
}

/**
 `Style` is a convenient wrapper for styling the appearance of various interface
 components throughout the Navigation UI.
 */
@objc(MBStyle)
public class Style: NSObject {
    
    public var traitCollection: UITraitCollection
    
    /**
     Initializes a style that will be applied for any system traits of an
     interface’s environment.
     */
    convenience override public init() {
        self.init(traitCollection: UITraitCollection())
    }
    
    /**
     Initializes a style for a specific system trait(s) of an interface’s
     environment.
     */
    required public init(traitCollection: UITraitCollection) {
        self.traitCollection = traitCollection
        super.init()
    }
    
    ///  General styling
    
    /**
     `tintColor` is used for guidance arrow, highlighted text, progress bar and
     more.
     */
    public var tintColor: UIColor?
    
    /**
     `primaryTextColor` sets the color for titles and other prominent information.
     */
    public var primaryTextColor: UIColor?
    
    /**
     `secondaryTextColor` sets the color for subtitles and other subtle
     information.
    */
    public var secondaryTextColor: UIColor?
    
    /**
     `buttonTextColor` sets the text color on buttons for normal state.
     */
    public var buttonTextColor: UIColor?
    
    /**
     `lineColor` sets the color of dividers and separators.
     */
    public var lineColor: UIColor?
    
    /// Maneuver view (Page view)
    
    /**
     `maneuverViewBackgroundColor` sets the background color of the maneuver
     view, positioned at the top.
     */
    public var maneuverViewBackgroundColor: UIColor?
    
    /**
     `maneuverViewHeight` sets the height of the maneuver view.
     */
    public var maneuverViewHeight: CGFloat?
    
    /// Table view (Drawer)
    
    /**
     `headerBackgroundColor` sets the color of the drawer header, positioned at
     the bottom.
     */
    public var headerBackgroundColor: UIColor?
    
    /**
     `headerTitleLabelColor` sets the color of the title in the header view,
     positioned at the top.
     */
    public var headerTitleLabelColor: UIColor?
    
    /**
     `headerSubtitleLabelColor` sets the color of the subtitle in the header
     view, positioned at the bottom of the header.
     */
    public var headerSubtitleLabelColor: UIColor?
    
    /**
     `cellTitleLabelFont` sets the font of the title labels in table views.
     */
    public var cellTitleLabelFont: UIFont?
    
    /**
     `cellTitleLabelTextColor` sets the title text color in table views.
     */
    public var cellTitleLabelTextColor: UIColor?
    
    /**
     `cellSubtitleLabelFont` sets the font of the subtitle label in table views.
     */
    public var cellSubtitleLabelFont: UIFont?
    
    /**
     `cellSubtitleLabelTextColor` sets the text color of the subtitle label in
     table views.
     */
    public var cellSubtitleLabelTextColor: UIColor?
    
    /**
     `wayNameTextColor` sets the color for the current way name label.
     */
    public var wayNameTextColor: UIColor?
    
    /**
     `wayNameLabelFont` sets the font of the current way name label.
     */
    public var wayNameLabelFont: UIFont?
    
    /**
     `defaultStyle` returns the default style for Mapbox Navigation SDK.
     */
    public class var defaultStyle: Style {
        let style = Style(traitCollection: UITraitCollection())
        
        // General styling
        if let tintColor = UIApplication.shared.delegate?.window??.tintColor {
            style.tintColor = tintColor
        } else {
            style.tintColor = .defaultTint
        }
        
        style.primaryTextColor = .defaultPrimaryText
        style.secondaryTextColor = .defaultSecondaryText
        style.buttonTextColor = .defaultPrimaryText
        style.lineColor = .defaultLine
        
        // Maneuver view (Page view)
        style.maneuverViewBackgroundColor = .defaultManeuverViewBackground
        style.maneuverViewHeight = .defaultManeuverViewHeight
        
        // Table view (Drawer)
        style.headerBackgroundColor = .defaultHeaderBackground
        
        style.headerTitleLabelColor = .defaultHeaderTitleLabel
        style.headerSubtitleLabelColor = .defaultHeaderSubtitleLabel
        
        style.cellTitleLabelFont = .defaultPrimaryText
        style.cellTitleLabelTextColor = .defaultPrimaryText
        
        style.cellSubtitleLabelFont = .defaultSecondaryText
        style.cellSubtitleLabelTextColor = .defaultSecondaryText
        
        return style
    }
    
    /**
     Applies the style for all changed properties.
     */
    public func apply() {
        // General styling
        
        if let color = tintColor {
            NavigationMapView.appearance(for: traitCollection).tintColor = color
            ProgressBar.appearance(for: traitCollection).backgroundColor = color
            Button.appearance(for: traitCollection).tintColor = color
            
            HighlightedButton.appearance(for: traitCollection).setTitleColor(color, for: .normal)
            ToggleView.appearance(for: traitCollection).tintColor = color
            ToggleView.appearance(for: traitCollection).onTintColor = color
            
            IconImageView.appearance(for: traitCollection).tintColor = color
        }
        
        if let color = primaryTextColor {
            TitleLabel.appearance(for: traitCollection).textColor = color
            CellTitleLabel.appearance(for: traitCollection).textColor = color
            HeaderTitleLabel.appearance(for: traitCollection).textColor = color
        }
        
        if let color = secondaryTextColor {
            SubtitleLabel.appearance(for: traitCollection).textColor = color
            CellSubtitleLabel.appearance(for: traitCollection).textColor = color
            HeaderSubtitleLabel.appearance(for: traitCollection).textColor = color
        }
        
        if let color = buttonTextColor {
            Button.appearance(for: traitCollection).textColor = color
        }
        
        if let color = lineColor {
            // Line view can be a dashed line view so we add a lineColor to avoid changing the background.
            LineView.appearance(for: traitCollection).lineColor = color
            // Separator view can also be a divider (vertical/horizontal) with a solid background color.
            SeparatorView.appearance(for: traitCollection).backgroundColor = color
        }
        
        // Maneuver page view controller
        
        if let color = maneuverViewBackgroundColor {
            ManeuverView.appearance(for: traitCollection).backgroundColor = color
        }
        
        if let height = maneuverViewHeight {
            ManeuverView.appearance(for: traitCollection).height = height
        }
        
        // Table view (drawer)
        
        if let color = headerBackgroundColor {
            RouteTableViewHeaderView.appearance(for: traitCollection).backgroundColor = color
        }
        
        if let color = headerTitleLabelColor {
            HeaderTitleLabel.appearance(for: traitCollection).textColor = color
        }
        
        if let color = headerSubtitleLabelColor {
            HeaderSubtitleLabel.appearance(for: traitCollection).textColor = color
        }
        
        if let font = cellTitleLabelFont {
            CellTitleLabel.appearance(for: traitCollection).font = font
        }
        
        if let color = cellTitleLabelTextColor {
            CellTitleLabel.appearance(for: traitCollection).textColor = color
        }
        
        if let font = cellSubtitleLabelFont {
            CellSubtitleLabel.appearance(for: traitCollection).font = font
        }
        
        if let color = cellSubtitleLabelTextColor {
            CellSubtitleLabel.appearance(for: traitCollection).textColor = color
        }
        
        if let color = wayNameTextColor {
            WayNameLabel.appearance(for: traitCollection).textColor = color
        }
        
        if let font = wayNameLabelFont {
            WayNameLabel.appearance(for: traitCollection).font = font
        }
    }
}

/**
 `MBButton` sets the tintColor according to the style.
 */
@objc(MBButton)
public class Button: StylableButton { }

/**
 `MBHighlightedButton` sets the button’s titleColor for normal control state
 according to the style in addition to the styling behavior inherited from
 `MBButton`.
 */
@objc(MBHighlightedButton)
public class HighlightedButton: Button { }

@objc(MBStylableLabel)
public class StylableLabel : UILabel { }

@objc(MBTitleLabel)
public class TitleLabel: StylableLabel { }
@objc(MBSubtitleLabel)
public class SubtitleLabel: StylableLabel { }

@objc(MBCellTitleLabel)
public class CellTitleLabel: StylableLabel { }
@objc(MBCellSubtitleLabel)
public class CellSubtitleLabel: StylableLabel { }

@objc(MBHeaderTitleLabel)
public class HeaderTitleLabel: StylableLabel { }

@objc(MBHeaderSubtitleLabel)
public class HeaderSubtitleLabel: StylableLabel { }

@objc(MBWayNameLabel)
public class WayNameLabel: StylableLabel { }

@objc(MBProgressBar)
public class ProgressBar: UIView { }

@objc(MBLineView)
public class LineView: UIView {
    dynamic var lineColor: UIColor = .defaultLine {
        didSet {
            setNeedsDisplay()
            setNeedsLayout()
        }
    }
}

@objc(MBToggleView)
public class ToggleView: UISwitch { }

@objc(MBIconImageView)
public class IconImageView: UIImageView { }

@objc(MBSeparatorView)
public class SeparatorView: UIView { }

@objc(MBStylableButton)
public class StylableButton: UIButton {
    dynamic var textColor: UIColor = .defaultPrimaryText {
        didSet {
            setTitleColor(textColor, for: .normal)
        }
    }
}

@objc(MBManeuverView)
class ManeuverView: UIView {
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    dynamic var height: CGFloat = .defaultManeuverViewHeight {
        didSet {
            heightConstraint.constant = height
            setNeedsUpdateConstraints()
        }
    }
}
