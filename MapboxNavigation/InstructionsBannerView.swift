import UIKit
import MapboxCoreNavigation

protocol InstructionsBannerViewDelegate: class {
    func didTapInstructionsBanner(_ sender: BaseInstructionsBannerView)
}

/// :nodoc:
@IBDesignable
@objc(MBInstructionsBannerView)
open class InstructionsBannerView: BaseInstructionsBannerView { }

/// :nodoc:
@objc(MBBaseInstructionsBannerView)
open class BaseInstructionsBannerView: UIControl {
    
    open override var backgroundColor: UIColor? {
        didSet {
            if leftView != nil {
                leftView.backgroundColor = backgroundColor
            }
        }
    }
    
    weak var contentView: UIView!
    weak var leftView: UIView!
    weak var maneuverView: ManeuverView!
    weak var primaryLabel: PrimaryLabel!
    weak var secondaryLabel: SecondaryLabel!
    weak var distanceLabel: DistanceLabel!
    weak var _separatorView: UIView!
    weak var separatorView: SeparatorView!
    weak var delegate: InstructionsBannerViewDelegate?
    
    var adaptiveElements: [AdaptiveElement] = []
    var constraintContainers: [AdaptiveConstraintContainer] = []
    
    var centerYConstraints = [NSLayoutConstraint]()
    var baselineConstraints = [NSLayoutConstraint]()
    
    var isOpen: Bool = false {
        didSet {
            // Force a regular size when the instuctions banner is open
            let traitCollection = isOpen ? UITraitCollection(verticalSizeClass: .regular) : self.traitCollection
            constraintContainers.forEach { $0.update(for: traitCollection) }
        }
    }
    
    fileprivate let distanceFormatter = DistanceFormatter(approximate: true)
    
    var distance: CLLocationDistance? {
        didSet {
            distanceLabel.unitRange = nil
            distanceLabel.valueRange = nil
            distanceLabel.distanceString = nil
            
            if let distance = distance {
                let distanceString = distanceFormatter.string(from: distance)
                let distanceUnit = distanceFormatter.unitString(fromValue: distance, unit: distanceFormatter.unit)
                guard let unitRange = distanceString.range(of: distanceUnit) else { return }
                let distanceValue = distanceString.replacingOccurrences(of: distanceUnit, with: "")
                guard let valueRange = distanceString.range(of: distanceValue) else { return }

                distanceLabel.unitRange = unitRange
                distanceLabel.valueRange = valueRange
                distanceLabel.distanceString = distanceString
            } else {
                distanceLabel.text = nil
            }
        }
    }
    
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
        setupAvailableBounds()
    }
    
    @IBAction func tappedInstructionsBanner(_ sender: Any) {
        delegate?.didTapInstructionsBanner(self)
    }
    
    func set(_ primaryInstruction: Instruction?, secondaryInstruction: Instruction?) {
        let isRegularVerticalSizeClass = traitCollection.verticalSizeClass != .compact
        primaryLabel.numberOfLines = secondaryInstruction == nil && isRegularVerticalSizeClass ? 2 : 1
        
        primaryLabel.instruction = primaryInstruction
        secondaryLabel.instruction = secondaryInstruction
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        maneuverView.isStart = true
        primaryLabel.text = "Primary Label"
        secondaryLabel.text = "Secondary Label"
        distanceLabel.text = "100m"
        backgroundColor = .blue
        contentView.backgroundColor = .gray
        leftView.backgroundColor = .lightGray
    }
}
