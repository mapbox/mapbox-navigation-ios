import UIKit

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
        NotificationCenter.default.addObserver(self, selector: #selector(preferredContentSizeChanged(_:)), name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func preferredContentSizeChanged(_ notification: Notification) {
        apply()
    }
    
    ///  General styling
    
    /**
     Sets the tint color for guidance arrow, highlighted text, progress bar
     and more.
     */
    public var tintColor: UIColor?
    
    /**
     Sets the font family for all labels.
     */
    public var fontFamily: String?
    
    /**
     Sets the text color on buttons for normal state.
     */
    public var buttonTextColor: UIColor?
    
    /**
     Sets the color of dividers and separators.
     */
    public var lineColor: UIColor?
    
    /// Maneuver view (Page view)
    
    /**
     Sets the background color of the maneuver view, positioned at the top.
     */
    public var maneuverViewBackgroundColor: UIColor?
    
    /**
     Sets the height of the maneuver view.
     */
    public var maneuverViewHeight: CGFloat?
    
    /**
     Sets the font on the distance label.
     */
    public var distanceLabelFont: UIFont?
    
    /**
     Sets the text color on the distance label.
     */
    public var distanceLabelTextColor: UIColor?
    
    /**
     Sets the font on the destination label.
     */
    public var destinationLabelFont: UIFont?
    
    /**
     Set the text color on the destination label.
     */
    public var destinationLabelTextColor: UIColor?
    
    /**
     Sets the prominent color on the turn arrow.
     */
    public var turnArrowPrimaryColor: UIColor?
    
    /**
     Sets the subtle color on the turn arrow.
     */
    public var turnArrowSecondaryColor: UIColor?
    
    /// Table view (Drawer)
    
    /**
     Sets the color of the drawer header, positioned at the bottom.
     */
    public var headerBackgroundColor: UIColor?
    
    /**
     Sets the font on the time remaining label.
     */
    public var timeRemainingLabelFont: UIFont?
    
    /**
     Sets the text color on the time remaining label.
     */
    public var timeRemainingLabelTextColor: UIColor?
    
    /**
     Sets the font on the distance remaining label.
     */
    public var distanceRemainingLabelFont: UIFont?
    
    /**
     Sets the text color on the distance remaining label.
     */
    public var distanceRemainingLabelTextColor: UIColor?
    
    /**
     Sets the font on the arrival time label.
     */
    public var arrivalTimeLabelFont: UIFont?
    
    /**
     Sets the text color on the ETA label.
     */
    public var arrivalTimeLabelTextColor: UIColor?
    
    /**
     Sets the font of the title labels in table views.
     */
    public var cellTitleLabelFont: UIFont?
    
    /**
     Sets the title text color in table views.
     */
    public var cellTitleLabelTextColor: UIColor?
    
    /**
     Sets the font of the subtitle label in table views.
     */
    public var cellSubtitleLabelFont: UIFont?
    
    /**
     Sets the text color of the subtitle label in table views.
     */
    public var cellSubtitleLabelTextColor: UIColor?
    
    /**
     Sets the color for the current way name label.
     */
    public var wayNameLabelTextColor: UIColor?
    
    /**
     Sets the font of the current way name label.
     */
    public var wayNameLabelFont: UIFont?
    
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
        
        if let color = wayNameLabelTextColor {
            WayNameLabel.appearance(for: traitCollection).textColor = color
        }
        
        if let font = wayNameLabelFont {
            WayNameLabel.appearance(for: traitCollection).font = font.adjustedFont.with(fontFamily: fontFamily)
        }
        
        if let color = turnArrowPrimaryColor {
            TurnArrowView.appearance(for: traitCollection).primaryColor = color
        }
        
        if let color = turnArrowSecondaryColor {
            TurnArrowView.appearance(for: traitCollection).secondaryColor = color
        }
        
        // Maneuver page view controller
        
        if let color = maneuverViewBackgroundColor {
            ManeuverView.appearance(for: traitCollection).backgroundColor = color
        }
        
        if let height = maneuverViewHeight {
            ManeuverView.appearance(for: traitCollection).height = height
        }
        
        if let font = distanceLabelFont {
            DistanceLabel.appearance(for: traitCollection).font = font.adjustedFont.with(fontFamily: fontFamily)
        }
        
        if let color = distanceLabelTextColor {
            DistanceLabel.appearance(for: traitCollection).textColor = color
        }
        
        if let font = destinationLabelFont {
            DestinationLabel.appearance(for: traitCollection).font = font.adjustedFont.with(fontFamily: fontFamily)
        }
        
        if let color = destinationLabelTextColor {
            DestinationLabel.appearance(for: traitCollection).textColor = color
        }
        
        // Table view (drawer)
        
        if let color = headerBackgroundColor {
            RouteTableViewHeaderView.appearance(for: traitCollection).backgroundColor = color
        }
        
        if let color = timeRemainingLabelTextColor {
            TimeRemainingLabel.appearance(for: traitCollection).textColor = color
        }
        
        if let font = timeRemainingLabelFont {
            TimeRemainingLabel.appearance(for: traitCollection).font = font.adjustedFont.with(fontFamily: fontFamily)
        }
        
        if let color = distanceRemainingLabelTextColor {
            DistanceRemainingLabel.appearance(for: traitCollection).textColor = color
        }
        
        if let font = distanceRemainingLabelFont {
            DistanceRemainingLabel.appearance(for: traitCollection).font = font.adjustedFont.with(fontFamily: fontFamily)
        }
        
        if let color = arrivalTimeLabelTextColor {
            ArrivalTimeLabel.appearance(for: traitCollection).textColor = color
        }
        
        if let font = arrivalTimeLabelFont {
            ArrivalTimeLabel.appearance(for: traitCollection).font = font.adjustedFont.with(fontFamily: fontFamily)
        }
        
        if let font = cellTitleLabelFont {
            CellTitleLabel.appearance(for: traitCollection).font = font.adjustedFont.with(fontFamily: fontFamily)
        }
        
        if let color = cellTitleLabelTextColor {
            CellTitleLabel.appearance(for: traitCollection).textColor = color
        }
        
        if let font = cellSubtitleLabelFont {
            CellSubtitleLabel.appearance(for: traitCollection).font = font.adjustedFont.with(fontFamily: fontFamily)
        }
        
        if let color = cellSubtitleLabelTextColor {
            CellSubtitleLabel.appearance(for: traitCollection).textColor = color
        }
    }
}

/**
 :nodoc:
 `MBButton` sets the tintColor according to the style.
 */
@objc(MBButton)
public class Button: StylableButton { }

/**
 :nodoc:
 `HighlightedButton` sets the button’s titleColor for normal control state
 according to the style in addition to the styling behavior inherited from
 `Button`.
 */
@objc(MBHighlightedButton)
public class HighlightedButton: Button { }

/// :nodoc:
@objc(MBStylableLabel)
public class StylableLabel : UILabel { }

/// :nodoc:
@objc(MBDistanceLabel)
public class DistanceLabel: StylableLabel { }

/// :nodoc:
@objc(MBDestinationLabel)
public class DestinationLabel: StylableLabel {
    typealias AvailableBoundsHandler = () -> (CGRect)
    var availableBounds: AvailableBoundsHandler!
    var unabridgedText: String? {
        didSet {
            super.text = unabridgedText?.abbreviated(toFit: availableBounds(), font: font)
        }
    }
}

/// :nodoc:
@objc(MBTimeRemainingLabel)
public class TimeRemainingLabel: StylableLabel { }

/// :nodoc:
@objc(MBDistanceRemainingLabel)
public class DistanceRemainingLabel: StylableLabel { }

/// :nodoc:
@objc(MBArrivalTimeLabel)
public class ArrivalTimeLabel: StylableLabel { }

/// :nodoc:
@objc(MBTitleLabel)
public class TitleLabel: StylableLabel { }

/// :nodoc:
@objc(MBSubtitleLabel)
public class SubtitleLabel: StylableLabel { }

/// :nodoc:
@objc(MBCellTitleLabel)
public class CellTitleLabel: StylableLabel { }

/// :nodoc:
@objc(MBCellSubtitleLabel)
public class CellSubtitleLabel: StylableLabel { }

/// :nodoc:
@objc(MBWayNameLabel)
public class WayNameLabel: StylableLabel { }

/// :nodoc:
@objc(MBProgressBar)
public class ProgressBar: UIView { }

/// :nodoc:
@objc(MBLineView)
public class LineView: UIView {
    dynamic var lineColor: UIColor = .black {
        didSet {
            setNeedsDisplay()
            setNeedsLayout()
        }
    }
}

/// :nodoc:
@objc(MBSeparatorView)
public class SeparatorView: UIView { }

/// :nodoc:
@objc(MBStylableButton)
public class StylableButton: UIButton {
    dynamic var textColor: UIColor = .black {
        didSet {
            setTitleColor(textColor, for: .normal)
        }
    }
}

@objc(MBManeuverView)
class ManeuverView: UIView {
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    dynamic var height: CGFloat = 100 {
        didSet {
            heightConstraint.constant = height
            setNeedsUpdateConstraints()
        }
    }
}
