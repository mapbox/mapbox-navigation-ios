import UIKit
import MapboxCoreNavigation
import MapboxDirections

protocol InstructionsBannerViewDelegate: class {
    func didTapInstructionsBanner(_ sender: BaseInstructionsBannerView)
}

/// :nodoc:
@IBDesignable
@objc(MBInstructionsBannerView)
open class InstructionsBannerView: BaseInstructionsBannerView { }

/// :nodoc:
open class BaseInstructionsBannerView: UIControl {
    
    weak var maneuverView: ManeuverView!
    weak var primaryLabel: PrimaryLabel!
    @objc dynamic weak var secondaryLabel: SecondaryLabel!
    weak var distanceLabel: DistanceLabel!
    weak var dividerView: UIView!
    weak var _separatorView: UIView!
    weak var separatorView: SeparatorView!
    weak var delegate: InstructionsBannerViewDelegate?
    
    var centerYConstraints = [NSLayoutConstraint]()
    var baselineConstraints = [NSLayoutConstraint]()
    
    private var alignmentObserver: NSKeyValueObservation?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        setupViews()
        setupLayout()
        centerYAlignInstructions()
        setupAvailableBounds()
        
        alignmentObserver = secondaryLabel.observe(\.instruction) { [unowned self] (label, change) in
            if label.instruction == nil {
                self.primaryLabel.numberOfLines = 2
                self.centerYAlignInstructions()
            } else {
                self.primaryLabel.numberOfLines = 1
                self.baselineAlignInstructions()
            }
        }
    }
    
    @IBAction func tappedInstructionsBanner(_ sender: Any) {
        delegate?.didTapInstructionsBanner(self)
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        maneuverView.isStart = true
        primaryLabel.instruction = [VisualInstructionComponent(type: .destination, text: "Primary text label", imageURL: nil)]
        distanceLabel.attributedText = DistanceFormatter(approximate: true).attributedDistanceString(from: 100, for: distanceLabel)
    }
}

