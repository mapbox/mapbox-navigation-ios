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
     Sets the tint color on the map view.
     */
    public var mapViewTintColor: UIColor?
    
    /**
     Sets the status bar style.
     `UIViewControllerBasedStatusBarAppearance` must be set to NO for this property to have any effect.
     */
    public var statusBarStyle: UIStatusBarStyle?
    
    /**
     Sets the font family for all labels.
     */
    public var fontFamily: String?
    
    /**
     Sets the text color on buttons for normal state.
     */
    public var buttonTextColor: UIColor?
    
    /**
     Sets the background color on the floating buttons.
     */
    public var floatingButtonBackgroundColor: UIColor?
    
    /**
     Sets the tint color on the floating buttons.
     */
    public var floatingButtonTintColor: UIColor?
    
    /**
     Sets the background color of the lane views.
     */
    public var lanesViewBackgroundColor: UIColor?
    
    /**
     Sets the lane views primary color.
     */
    public var laneViewPrimaryColor: UIColor?
    
    /**
     Sets the lane views secondary color.
     */
    public var laneViewSecondaryColor: UIColor?
    
    /**
     Sets the color of dividers and separators.
     */
    public var lineColor: UIColor?
    
    /**
     Sets the background of the resume bottom.
     */
    public var resumeButtonBackgroundColor: UIColor?
    
    /**
     Sets the tint color of the resume button.
     */
    public var resumeButtonTintColor: UIColor?
    
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
     Sets an alternate color used throughout the UI to denote low traffic congestion. Not used to style the route line.
     */
    public var lowTrafficTextColor: UIColor?
    
    /**
     Describes the situations in which the style should be used. By default, the style will be used during the daytime.
     */
    public var styleType: StyleType = .lightStyle
    
    /**
     Map style to be used for the style.
     */
    public var mapStyleURL: URL?
    
    /**
     Applies the style for all changed properties.
     */
    open func apply() {
        
        // General styling
        
        if let color = tintColor {
            NavigationMapView.appearance(for: traitCollection).tintColor = color
            ProgressBar.appearance(for: traitCollection).barColor = color
            Button.appearance(for: traitCollection).tintColor = color
            HighlightedButton.appearance(for: traitCollection).setTitleColor(color, for: .normal)
            ResumeButton.appearance(for: traitCollection).tintColor = color
        }
        
        if let color = mapViewTintColor {
            NavigationMapView.appearance(for: traitCollection).tintColor = color
        }
        
        if let statusBarStyle = statusBarStyle {
            UIApplication.shared.statusBarStyle = statusBarStyle
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
        
        if let color = floatingButtonBackgroundColor {
            FloatingButton.appearance(for: traitCollection).backgroundColor = color
        }
        
        if let color = floatingButtonTintColor {
            FloatingButton.appearance(for: traitCollection).tintColor = color
        }
        
        if let color = lanesViewBackgroundColor {
            LanesView.appearance(for: traitCollection).backgroundColor = color
        }
        
        if let color = laneViewPrimaryColor {
            LaneArrowView.appearance(for: traitCollection).primaryColor = color
        }
        
        if let color = laneViewSecondaryColor {
            LaneArrowView.appearance(for: traitCollection).secondaryColor = color
        }
        
        if let color = resumeButtonBackgroundColor {
            ResumeButton.appearance(for: traitCollection).backgroundColor = color
        }
        
        if let color = resumeButtonTintColor {
            ResumeButton.appearance(for: traitCollection).tintColor = color
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
        
        if let color = lowTrafficTextColor {
            NavigationMapView.appearance(for: traitCollection).lowTrafficTextColor = color
        }
    }
}

/**
 :nodoc:
 `MBButton` sets the tintColor according to the style.
 */
@objc(MBButton)
open class Button: StylableButton { }

/// :nodoc:
@objc(MBFloatingButton)
open class FloatingButton: Button { }

/// :nodoc:
@objc(MBLanesView)
public class LanesView: UIView { }

/**
 :nodoc:
 `HighlightedButton` sets the button’s titleColor for normal control state according to the style in addition to the styling behavior inherited from
 `Button`.
 */
@objc(MBHighlightedButton)
public class HighlightedButton: Button { }

@IBDesignable
@objc(MBResumeButton)
public class ResumeButton: UIControl {
    public override dynamic var tintColor: UIColor! {
        didSet {
            imageView.tintColor = tintColor
            titleLabel.textColor = tintColor
        }
    }
    
    let imageView = UIImageView(image: UIImage(named: "location", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate))
    let titleLabel = UILabel()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        commonInit()
    }
    
    func commonInit() {
        titleLabel.text = NSLocalizedString("RESUME", bundle: .mapboxNavigation, value: "Resume", comment: "Button title for resume tracking")
        titleLabel.sizeToFit()
        addSubview(imageView)
        addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false
        
        let views = ["label": titleLabel, "imageView": imageView]
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[imageView]-8-[label]-8-|", options: [], metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|->=12-[imageView]->=12-|", options: [], metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|->=12-[label]->=12-|", options: [], metrics: nil, views: views))
        setNeedsUpdateConstraints()
        
        applyDefaultCornerRadiusShadow()
    }
}

/// :nodoc:
@objc(MBStylableLabel)
open class StylableLabel : UILabel { }

/// :nodoc:
@objc(MBDistanceLabel)
open class DistanceLabel: StylableLabel { }

/// :nodoc:
@objc(MBDestinationLabel)
open class DestinationLabel: StylableLabel {
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
open class TimeRemainingLabel: StylableLabel { }

/// :nodoc:
@objc(MBDistanceRemainingLabel)
open class DistanceRemainingLabel: StylableLabel { }

/// :nodoc:
@objc(MBArrivalTimeLabel)
open class ArrivalTimeLabel: StylableLabel { }

/// :nodoc:
@objc(MBTitleLabel)
open class TitleLabel: StylableLabel { }

/// :nodoc:
@objc(MBSubtitleLabel)
open class SubtitleLabel: StylableLabel { }

/// :nodoc:
@objc(MBCellTitleLabel)
open class CellTitleLabel: StylableLabel { }

/// :nodoc:
@objc(MBCellSubtitleLabel)
open class CellSubtitleLabel: StylableLabel { }

/// :nodoc:
@objc(MBWayNameLabel)
open class WayNameLabel: StylableLabel { }

@objc(MBWayNameView)
open class WayNameView: UIView {
    
    dynamic var borderColor: UIColor = .white {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    open override func layoutSubviews() {
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
open class StylableButton: UIButton {
    dynamic open var textColor: UIColor = .black {
        didSet {
            setTitleColor(textColor, for: .normal)
        }
    }
    
    dynamic open var borderColor: UIColor = .clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    dynamic open var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    dynamic open var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
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
    
    func show(_ title: String, showSpinner: Bool) {
        textLabel.text = title
        activityIndicatorView.hidesWhenStopped = true
        if showSpinner {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
        
        guard isHidden == true else { return }
        
        UIView.defaultAnimation(0.3, animations: {
            self.isHidden = false
        }, completion: nil)
    }
    
    func hide(delay: TimeInterval = 0, animated: Bool = true) {
        
        if animated {
            guard isHidden == false else { return }
            UIView.defaultAnimation(0.3, delay: delay, animations: {
                self.isHidden = true
            }, completion: { (completed) in
                self.activityIndicatorView.stopAnimating()
            })
        } else {
            self.activityIndicatorView.stopAnimating()
            self.isHidden = true
        }
    }
}
