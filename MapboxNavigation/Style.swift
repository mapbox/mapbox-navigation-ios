import UIKit

/**
 `Style` is a convenient wrapper for styling the appearance of various interface components throughout the Navigation UI.
 
 Styles are applied globally using `UIAppearance`. You should call `Style.apply()` to apply the style to the `NavigationViewController`.
 */
@objc(MBStyle)
open class Style: NSObject {
    
    public var traitCollection: UITraitCollection
    
    /**
     Initializes a style that will be applied for any system traits of an interface’s environment.
     */
    convenience override public init() {
        self.init(traitCollection: UITraitCollection())
    }
    
    /**
     Initializes a style for a specific system trait(s) of an interface’s environment.
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
     Sets the tint color for guidance arrow, highlighted text, progress bar and more.
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
     Sets the background color of the current way name view.
     */
    public var wayNameViewBackgroundColor: UIColor?
    
    /**
     Sets the border color of the current way name view.
     */
    public var wayNameViewBorderColor: UIColor?
    
    /**
     Sets the color for the current way name label.
     */
    public var wayNameLabelTextColor: UIColor?
    
    /**
     Sets the font of the current way name label.
     */
    public var wayNameLabelFont: UIFont?
    
    /**
     Sets the color if the route’s casing color.
     */
    public var routeCasingColor: UIColor?
    
    /**
     Sets the traffic color for unknown congestion.
     */
    public var trafficUnknownColor: UIColor?
    
    /**
     Sets the traffic color for low congestion.
     */
    public var trafficLowColor: UIColor?
    
    /**
     Sets the traffic color for moderate congestion.
     */
    public var trafficModerateColor: UIColor?
    
    /**
     Sets the traffic color for heavy congestion.
     */
    public var trafficHeavyColor: UIColor?
    
    /**
     Sets the traffic color for severe congestion.
     */
    public var trafficSevereColor: UIColor?
    
    /**
     Applies the style for all changed properties.
     */
    public func apply() {
        
        // General styling
        
        if let color = tintColor {
            NavigationMapView.appearance(for: traitCollection).tintColor = color
            ProgressBar.appearance(for: traitCollection).barColor = color
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
        
        if let color = wayNameViewBackgroundColor {
            WayNameView.appearance(for: traitCollection).backgroundColor = color
        }
        
        if let color = wayNameViewBorderColor {
            WayNameView.appearance(for: traitCollection).borderColor = color
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
        
        // Traffic
        
        if let color = routeCasingColor {
            NavigationMapView.appearance(for: traitCollection).routeCasingColor = color
        }
        
        if let color = trafficUnknownColor {
            NavigationMapView.appearance(for: traitCollection).trafficUnknownColor = color
        }
        
        if let color = trafficLowColor {
            NavigationMapView.appearance(for: traitCollection).trafficLowColor = color
        }
        
        if let color = trafficModerateColor {
            NavigationMapView.appearance(for: traitCollection).trafficModerateColor = color
        }
        
        if let color = trafficHeavyColor {
            NavigationMapView.appearance(for: traitCollection).trafficHeavyColor = color
        }
        
        if let color = trafficSevereColor {
            NavigationMapView.appearance(for: traitCollection).trafficSevereColor = color
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
 `HighlightedButton` sets the button’s titleColor for normal control state according to the style in addition to the styling behavior inherited from
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

@objc(MBWayNameView)
public class WayNameView: UIView {
    
    dynamic var borderColor: UIColor = .white {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.midY
    }
}

/// :nodoc:
@objc(MBProgressBar)
public class ProgressBar: UIView {
    
    let bar = UIView()
    
    dynamic var barColor: UIColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1) {
        didSet {
            bar.backgroundColor = barColor
        }
    }
    
    // Set the progress between 0.0-1.0
    var progress: CGFloat = 0 {
        didSet {
            UIView.defaultAnimation(0.5, animations: { 
                self.updateProgressBar()
                self.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func dock(on view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bar]-0-|", options: [], metrics: nil, views: ["bar": self]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[bar(3)]-0-|", options: [], metrics: nil, views: ["bar": self]))
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if bar.superview == nil {
            addSubview(bar)
        }
        
        updateProgressBar()
    }
    
    func updateProgressBar() {
        if let superview = superview {
            bar.frame = CGRect(origin: .zero, size: CGSize(width: superview.bounds.width*progress, height: 3))
        }
    }
}

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

/// :nodoc:
@objc(MBManeuverView)
class ManeuverView: UIView { }

/// :nodoc:
@objc(MBManeuverContainerView)
class ManeuverContainerView: UIView {
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    dynamic var height: CGFloat = 100 {
        didSet {
            heightConstraint.constant = height
            setNeedsUpdateConstraints()
        }
    }
}

/// :nodoc:
@objc(MBStatusView)
class StatusView: UIView {
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    func show(_ title: String, showSpinner: Bool, duration: TimeInterval) {
        textLabel.text = title
        activityIndicatorView.isHidden = !showSpinner
        activityIndicatorView.startAnimating()
        
        updateConstraints(show: true)
        UIView.defaultAnimation(0.3, animations: {
            self.superview?.layoutIfNeeded()
        }) { (completed) in
            if completed && duration > 0 {
                self.hide(delay: duration, animated: true)
            }
        }
    }
    
    func hide(delay: TimeInterval = 0, animated: Bool = true) {
        if animated {
            updateConstraints(show: false)
            UIView.defaultAnimation(0.3, delay: delay, animations: {
                self.superview?.layoutIfNeeded()
            }, completion: { (completed) in
                self.activityIndicatorView.stopAnimating()
            })
        } else {
            updateConstraints(show: false)
            self.activityIndicatorView.stopAnimating()
            self.superview?.layoutIfNeeded()
        }
    }
    
    fileprivate func updateConstraints(show: Bool) {
        topConstraint.constant = show ? 0 : -bounds.height
        superview?.setNeedsUpdateConstraints()
    }
}
