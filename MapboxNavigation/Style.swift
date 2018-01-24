import UIKit

/**
 `Style` is a convenient wrapper for styling the appearance of various interface components throughout the Navigation UI.
 
 Styles are applied globally using `UIAppearance`. You should call `Style.apply()` to apply the style to the `NavigationViewController`.
 */
@objc(MBStyle)
open class Style: NSObject {
    
    ///  General styling
    
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
    @objc public var styleType: StyleType = .dayStyle
    
    /**
     Map style to be used for the style.
     */
    @objc open var mapStyleURL: URL = URL(string: "mapbox://styles/mapbox/navigation-guidance-day-v2")!
    
    /**
     Applies the style for all changed properties.
     */
    @objc open func apply() { }
    
    @objc public required override init() { }
}

/**
 :nodoc:
 `MBButton` sets the tintColor according to the style.
 */
@objc(MBButton)
open class Button: StylableButton { }

/// :nodoc:
@objc(MBCancelButton)
open class CancelButton: Button { }

/// :nodoc:
@objc(MBDismissButton)
open class DismissButton: Button { }

/// :nodoc:
@objc(MBFloatingButton)
open class FloatingButton: Button {
    var constrainedSize: CGSize? {
        didSet {
            guard let size = constrainedSize else {
                widthAnchor.constraint(equalToConstant: 0).isActive = false
                heightAnchor.constraint(equalToConstant: 0).isActive = false
                return
            }
            widthAnchor.constraint(equalToConstant: size.width).isActive = true
            heightAnchor.constraint(equalToConstant: size.height).isActive = true
        }
    }
}

/// :nodoc:
@objc(MBReportButton)
public class ReportButton: Button {
    
    let padding: CGFloat = 10
    let downConstant: CGFloat = 10
    
    var upConstant: CGFloat {
        return -bounds.height-(padding * 2)
    }
    
    func slideDown(constraint: NSLayoutConstraint, interval: TimeInterval) {
        guard isHidden == true else { return }
        
        isHidden = false
        constraint.constant = downConstant
        setNeedsUpdateConstraints()
        UIView.defaultAnimation(0.5, animations: {
            self.superview?.layoutIfNeeded()
        }) { (completed) in
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(ReportButton.slideUp(constraint:)), object: nil)
            self.perform(#selector(ReportButton.slideUp(constraint:)), with: constraint, afterDelay: interval)
        }
    }
    
    @objc func slideUp(constraint: NSLayoutConstraint) {
        constraint.constant = upConstant
        setNeedsUpdateConstraints()
        UIView.defaultSpringAnimation(0.5, animations: {
            self.superview?.layoutIfNeeded()
        }) { (completed) in
            self.isHidden = true
        }
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
@objc(MBStylableLabel)
open class StylableLabel: UILabel {
    // Workaround the fact that UILabel properties are not marked with UI_APPEARANCE_SELECTOR
    @objc dynamic open var normalTextColor: UIColor = .black {
        didSet {
            textColor = normalTextColor
        }
    }
    
    @objc dynamic open var normalFont: UIFont = .systemFont(ofSize: 16) {
        didSet {
            font = normalFont
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
    @objc dynamic public var valueFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .medium) {
        didSet { update() }
    }
    @objc dynamic public var unitFont: UIFont = UIFont.systemFont(ofSize: 11, weight: .medium) {
        didSet { update() }
    }
    
    var valueRange: Range<String.Index>? {
        didSet {
            update()
        }
    }
    
    var unitRange: Range<String.Index>? {
        didSet {
            update()
        }
    }
    
    var distanceString: String? {
        didSet {
            update()
        }
    }
    
    fileprivate func update() {
        guard let valueRange = valueRange, let unitRange = unitRange, let distanceString = distanceString else {
            return
        }

        let valueAttributes: [NSAttributedStringKey: Any] = [.foregroundColor: valueTextColor, .font: valueFont]
        let unitAttributes: [NSAttributedStringKey: Any] = [.foregroundColor: unitTextColor, .font: unitFont]

        let valueSubstring = distanceString[valueRange].trimmingCharacters(in: .whitespaces)
        let unitSubstring = distanceString[unitRange].trimmingCharacters(in: .whitespaces)
        let valueAttributedString = NSAttributedString(string: valueSubstring, attributes: valueAttributes)
        let unitAttributedString = NSAttributedString(string: unitSubstring, attributes: unitAttributes)

        let startsWithUnit = unitRange.lowerBound == distanceString.wholeRange.lowerBound
        let attributedString = NSMutableAttributedString()

        attributedString.append(startsWithUnit ? unitAttributedString : valueAttributedString)
        attributedString.append(NSAttributedString(string: "\u{200A}", attributes: unitAttributes))
        attributedString.append(startsWithUnit ? valueAttributedString : unitAttributedString)

        attributedText = attributedString
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
@objc(MBWayNameLabel)
@IBDesignable
open class WayNameLabel: StylableLabel {
    
    /// :nodoc:
    open var textInsets: UIEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
    
    open override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height += textInsets.top + textInsets.bottom
        size.width += textInsets.left + textInsets.right
        return size
    }
    
    @objc dynamic public var borderColor: UIColor = .white {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    @objc open override var backgroundColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override open func drawText(in rect: CGRect) {
        backgroundColor?.setFill()
        clipsToBounds = true
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.fill(rect)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, textInsets))
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
    
    var barHeight: CGFloat = 3
    
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
    
    func setProgress(_ progress: CGFloat, animated: Bool) {
        UIView.defaultAnimation(0.5, animations: {
            self.progress = progress
        }, completion: nil)
    }
    
    func dock(on view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bar]-0-|", options: [], metrics: nil, views: ["bar": self]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[bar(\(bounds.height))]-0-|", options: [], metrics: nil, views: ["bar": self]))
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
            bar.frame = CGRect(origin: .zero, size: CGSize(width: superview.bounds.width*progress, height: bounds.height))
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
public class SeparatorView: UIView { }

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
    
    @objc dynamic var height: CGFloat = 100 {
        didSet {
            heightConstraint.constant = height
            setNeedsUpdateConstraints()
        }
    }
}

/// :nodoc:
@objc(MBInstructionsBannerContentView)
open class InstructionsBannerContentView: UIView { }

/// :nodoc:
@objc(MBBottomBannerContentView)
open class BottomBannerContentView: UIView { }

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
