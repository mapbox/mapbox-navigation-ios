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
    
    /**
     Applies the style for all changed properties.
     */
    @objc open func apply() { }
    
    @objc public required override init() { }
}

/**
 :nodoc:
 `Button` sets the tintColor according to the style.
 */
@objc(MBButton)
open class Button: StylableButton { }

/// :nodoc:
@objc(MBCancelButton)
open class CancelButton: Button { }

/// :nodoc:
@objc(MBDismissButton)
open class DismissButton: Button { }

/**
 A rounded button with an icon that is designed to float above `NavigationMapView`.
 */
@objc(MBFloatingButton)
open class FloatingButton: Button {
    /**
     The default size of a floating button.
     */
    public static let buttonSize = CGSize(width: 50, height: 50)
    
    static let sizeConstraintPriority = UILayoutPriority(999.0) //Don't fight with the stack view (superview) when it tries to hide buttons.
    
    lazy var widthConstraint: NSLayoutConstraint = {
        let constraint = self.widthAnchor.constraint(equalToConstant: FloatingButton.buttonSize.width)
        constraint.priority = FloatingButton.sizeConstraintPriority
        return constraint
    }()
    lazy var heightConstraint: NSLayoutConstraint = {
        let constraint = self.heightAnchor.constraint(equalToConstant: FloatingButton.buttonSize.height)
        constraint.priority = FloatingButton.sizeConstraintPriority
        return constraint
    }()
        
    var constrainedSize: CGSize? {
        didSet {
            guard let size = constrainedSize else {
                NSLayoutConstraint.deactivate([widthConstraint, heightConstraint])
                return
            }
            widthConstraint.constant = size.width
            heightConstraint.constant = size.height
            NSLayoutConstraint.activate([widthConstraint, heightConstraint])
        }
    }
    
    /**
     Return a `FloatingButton` with given images and size.
     
     - parameter image: The `UIImage` of this button.
     - parameter selectedImage: The `UIImage` of this button when selected.
     - parameter size: The size of this button,  or `FloatingButton.buttonSize` if this argument is not specified.
     */
    public class func rounded<T: FloatingButton>(image: UIImage? = nil, selectedImage: UIImage? = nil, size: CGSize = FloatingButton.buttonSize) -> T {
        let button = T.init(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.constrainedSize = size
        button.setImage(image, for: .normal)
        if let selected = selectedImage { button.setImage(selected, for: .selected) }
        button.applyDefaultCornerRadiusShadow(cornerRadius: size.width / 2)
        return button
    }
}

/// :nodoc:
@objc(MBReportButton)
public class ReportButton: Button {
    static let defaultInsets: UIEdgeInsets = 10.0
    static let defaultCornerRadius: CGFloat = 4.0
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        contentEdgeInsets = ReportButton.defaultInsets
        applyDefaultCornerRadiusShadow(cornerRadius: ReportButton.defaultCornerRadius)
    }
}

/**
 :nodoc:
 `HighlightedButton` sets the button’s titleColor for normal control state according to the style in addition to the styling behavior inherited from
 `Button`.
 */
@objc(MBHighlightedButton)
public class HighlightedButton: Button { }

/// :nodoc:
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
@objc(MBDraggableView)
open class StepListIndicatorView: UIView {
    // Workaround the fact that UIView properties are not marked with UI_APPEARANCE_SELECTOR
    @objc dynamic open var gradientColors: [UIColor] = [.gray, .lightGray, .gray] {
        didSet {
            setNeedsLayout()
        }
    }
    
    fileprivate lazy var blurredEffectView: UIVisualEffectView = {
        return UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    }()

    override open func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.midY
        layer.masksToBounds = true
        layer.opacity = 0.25
        applyGradient(colors: gradientColors)
        addBlurredEffect(view: blurredEffectView, to: self)
    }
    
    fileprivate func addBlurredEffect(view: UIView, to parentView: UIView)  {
        guard !view.isDescendant(of: parentView) else { return }
        view.frame = parentView.bounds
        parentView.addSubview(view)
    }
}

/// :nodoc:
@objc(MBStylableLabel)
open class StylableLabel: UILabel {
    // Workaround the fact that UILabel properties are not marked with UI_APPEARANCE_SELECTOR
    @objc dynamic open var normalTextColor: UIColor = .black {
        didSet { update() }
    }
    
    @objc dynamic open var normalFont: UIFont = .systemFont(ofSize: 16) {
        didSet { update() }
    }

    @objc dynamic public var textColorHighlighted: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) {
        didSet { update() }
    }

    @objc public var showHighlightedTextColor: Bool = false {
        didSet { update() }
    }

    open func update() {
        textColor = showHighlightedTextColor ? textColorHighlighted : normalTextColor
        font = normalFont
    }
}

/// :nodoc:
@objc(MBStylableView)
open class StylableView: UIView {
    @objc dynamic public var borderWidth: CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @objc dynamic public var cornerRadius: CGFloat = 0.0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    @objc dynamic public var borderColor: UIColor? {
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

/// :nodoc:
@objc(MBStylableTextView)
open class StylableTextView: UITextView {
    // Workaround the fact that UITextView properties are not marked with UI_APPEARANCE_SELECTOR
    @objc dynamic open var normalTextColor: UIColor = .black {
        didSet {
            textColor = normalTextColor
        }
    }
}

/// :nodoc:
@objc(MBDistanceLabel)
open class DistanceLabel: StylableLabel {
    @objc dynamic public var valueTextColor: UIColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1) {
        didSet { update() }
    }
    @objc dynamic public var unitTextColor: UIColor = #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6274509804, alpha: 1) {
        didSet { update() }
    }
    @objc dynamic public var valueTextColorHighlighted: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) {
        didSet { update() }
    }
    @objc dynamic public var unitTextColorHighlighted: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) {
        didSet { update() }
    }
    @objc dynamic public var valueFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .medium) {
        didSet { update() }
    }
    @objc dynamic public var unitFont: UIFont = UIFont.systemFont(ofSize: 11, weight: .medium) {
        didSet { update() }
    }
    
    /**
     An attributed string indicating the distance along with a unit.
     
     - precondition: `NSAttributedStringKey.quantity` should be applied to the
        numeric quantity.
     */
    var attributedDistanceString: NSAttributedString? {
        didSet {
            update()
        }
    }
    
    open override func update() {
        guard let attributedDistanceString = attributedDistanceString else {
            return
        }
        
        // Create a copy of the attributed string that emphasizes the quantity.
        let emphasizedDistanceString = NSMutableAttributedString(attributedString: attributedDistanceString)
        let wholeRange = NSRange(location: 0, length: emphasizedDistanceString.length)
        var hasQuantity = false
        emphasizedDistanceString.enumerateAttribute(.quantity, in: wholeRange, options: .longestEffectiveRangeNotRequired) { (value, range, stop) in
            let foregroundColor: UIColor
            let font: UIFont
            if let _ = emphasizedDistanceString.attribute(.quantity, at: range.location, effectiveRange: nil) {
                foregroundColor = showHighlightedTextColor ? valueTextColorHighlighted : valueTextColor
                font = valueFont
                hasQuantity = true
            } else {
                foregroundColor = showHighlightedTextColor ? unitTextColorHighlighted : unitTextColor
                font = unitFont
            }
            emphasizedDistanceString.addAttributes([.foregroundColor: foregroundColor, .font: font], range: range)
        }
        
        // As a failsafe, if no quantity was found, emphasize the entire string.
        if !hasQuantity {
            emphasizedDistanceString.addAttributes([.foregroundColor: valueTextColor, .font: valueFont], range: wholeRange)
        }
        
        // Replace spaces with hair spaces to economize on horizontal screen
        // real estate. Formatting the distance with a short style would remove
        // spaces, but in English it would also denote feet with a prime
        // mark (′), which is typically used for heights, not distances.
        emphasizedDistanceString.mutableString.replaceOccurrences(of: " ", with: "\u{200A}", options: [], range: wholeRange)
        
        attributedText = emphasizedDistanceString
    }
}

/// :nodoc:
@objc(MBPrimaryLabel)
open class PrimaryLabel: InstructionLabel { }

/// :nodoc:
@objc(MBSecondaryLabel)
open class SecondaryLabel: InstructionLabel { }

/// :nodoc:
@objc(MBTimeRemainingLabel)
open class TimeRemainingLabel: StylableLabel {
    // Sets the text color for no or unknown traffic
    @objc dynamic public var trafficUnknownColor: UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
        didSet {
            textColor = trafficUnknownColor
        }
    }
    // Sets the text color for low traffic
    @objc dynamic public var trafficLowColor: UIColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
    // Sets the text color for moderate traffic
    @objc dynamic public var trafficModerateColor: UIColor = #colorLiteral(red:0.95, green:0.65, blue:0.31, alpha:1.0)
    // Sets the text color for heavy traffic
    @objc dynamic public var trafficHeavyColor: UIColor = #colorLiteral(red:0.91, green:0.20, blue:0.25, alpha:1.0)
    // Sets the text color for severe traffic
    @objc dynamic public var trafficSevereColor: UIColor = #colorLiteral(red:0.54, green:0.06, blue:0.22, alpha:1.0)
}

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
@objc(MBProgressBar)
public class ProgressBar: UIView {
    let bar = UIView()
    
    // Sets the color of the progress bar.
    @objc dynamic public var barColor: UIColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1) {
        didSet {
            bar.backgroundColor = barColor
        }
    }
    
    // Set the progress between 0.0-1.0
    var progress: CGFloat = 0 {
        didSet {
            self.updateProgressBar()
            self.layoutIfNeeded()
        }
    }
    
    override open var description: String {
        return super.description + "; progress = \(progress)"
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
            let origin: CGPoint
            if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                origin = CGPoint(x: superview.bounds.width * (1 - progress), y: 0)
            } else {
                origin = .zero
            }
            bar.frame = CGRect(origin: origin, size: CGSize(width: superview.bounds.width * progress, height: bounds.height))
        }
    }
}

/// :nodoc:
@objc(MBLineView)
public class LineView: UIView {
    // Set the line color on all line views.
    @objc dynamic public var lineColor: UIColor = .black {
        didSet {
            setNeedsDisplay()
            setNeedsLayout()
        }
    }
}

/// :nodoc:
@objc(MBSeparatorView)
public class SeparatorView: UIView {}

/// :nodoc:
@objc(MBStylableButton)
open class StylableButton: UIButton {
    // Sets the font on the button’s titleLabel
    @objc dynamic open var textFont: UIFont = UIFont.systemFont(ofSize: 20, weight: .medium) {
        didSet {
            titleLabel?.font = textFont
        }
    }
    
    // Sets the text color for normal state
    @objc dynamic open var textColor: UIColor = .black {
        didSet {
            setTitleColor(textColor, for: .normal)
        }
    }
    
    // Sets the border color
    @objc dynamic open var borderColor: UIColor = .clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    // Sets the border width
    @objc dynamic open var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    // Sets the corner radius
    @objc dynamic open var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
}

/// :nodoc:
@objc(MBManeuverContainerView)
open class ManeuverContainerView: UIView {
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    @objc dynamic public var height: CGFloat = 100 {
        didSet {
            heightConstraint.constant = height
            setNeedsUpdateConstraints()
        }
    }
}

/// :nodoc:
@objc(MBBannerContainerView)
open class BannerContainerView: UIView { }

/// :nodoc:
@objc(MBTopBannerView)
open class TopBannerView: UIView { }

/// :nodoc:
@objc(MBBottomBannerView)
open class BottomBannerView: UIView { }

open class BottomPaddingView: BottomBannerView { }

/// :nodoc:
@objc(MBMarkerView)
public class MarkerView: UIView {
    // Sets the inner color on the pin.
    @objc public dynamic var innerColor: UIColor = .white {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // Sets the shadow color under the marker view.
    @objc public dynamic var shadowColor: UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // Sets the color on the marker view.
    @objc public dynamic var pinColor: UIColor = #colorLiteral(red: 0.1493228376, green: 0.2374534607, blue: 0.333029449, alpha: 1) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // Sets the stroke color on the marker view.
    @objc public dynamic var strokeColor: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override public var intrinsicContentSize: CGSize {
        return CGSize(width: 39, height: 51)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = .clear
    }
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        StyleKitMarker.drawMarker(innerColor: innerColor, shadowColor: shadowColor, pinColor: pinColor, strokeColor: strokeColor)
    }
}
