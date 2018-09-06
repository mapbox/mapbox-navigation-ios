import UIKit
import MapboxCoreNavigation
import MapboxDirections

/**
 `InstructionsBannerViewDelegate` provides methods for reacting to user interactions in `InstructionsBannerView`.
 */
@objc(MBInstructionsBannerViewDelegate)
public protocol InstructionsBannerViewDelegate: class {
    
    /**
     Called when the user taps the `InstructionsBannerView`.
     */
    @objc(didTapInstructionsBanner:)
    optional func didTapInstructionsBanner(_ sender: BaseInstructionsBannerView)
    
    
    /**
     Called when the user drags either up or down on the `InstructionsBannerView`.
     */
    @objc(didDragInstructionsBanner:)
    optional func didDragInstructionsBanner(_ sender: BaseInstructionsBannerView)
}

/// :nodoc:
@IBDesignable
@objc(MBInstructionsBannerView)
open class InstructionsBannerView: BaseInstructionsBannerView { }

/// :nodoc:
open class BaseInstructionsBannerView: UIControl {
    
    weak var maneuverView: ManeuverView!
    weak var primaryLabel: PrimaryLabel!
    weak var secondaryLabel: SecondaryLabel!
    weak var distanceLabel: DistanceLabel!
    weak var dividerView: UIView!
    weak var _separatorView: UIView!
    weak var separatorView: SeparatorView!
    weak var stepListIndicatorView: StepListIndicatorView!
    public weak var delegate: InstructionsBannerViewDelegate? {
        didSet {
            stepListIndicatorView.isHidden = false
        }
    }
    
    weak var instructionDelegate: VisualInstructionDelegate? {
        didSet {
            primaryLabel.instructionDelegate = instructionDelegate
            secondaryLabel.instructionDelegate = instructionDelegate
        }
    }
    
    var centerYConstraints = [NSLayoutConstraint]()
    var baselineConstraints = [NSLayoutConstraint]()
    
    let distanceFormatter = DistanceFormatter(approximate: true)
    
    var distance: CLLocationDistance? {
        didSet {
            distanceLabel.attributedDistanceString = nil
            
            if let distance = distance {
                distanceLabel.attributedDistanceString = distanceFormatter.attributedString(for: distance)
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
        setupLayout()
        centerYAlignInstructions()
        setupAvailableBounds()
        stepListIndicatorView.isHidden = true
    }
    
    @objc func draggedInstructionsBanner(_ sender: Any) {
        if let gestureRecognizer = sender as? UIPanGestureRecognizer, gestureRecognizer.state == .ended, let delegate = delegate {
            stepListIndicatorView.isHidden = !stepListIndicatorView.isHidden
            delegate.didDragInstructionsBanner?(self)
        }
    }
    
    @objc func tappedInstructionsBanner(_ sender: Any) {
        if let delegate = delegate {
            stepListIndicatorView.isHidden = !stepListIndicatorView.isHidden
            delegate.didTapInstructionsBanner?(self)
        }
    }
    
    /**
     Updates the instructions banner info with a given `VisualInstructionBanner`.
     */
    @objc(updateForVisualInstructionBanner:)
    public func update(for instruction: VisualInstructionBanner?) {
        let secondaryInstruction = instruction?.secondaryInstruction
        primaryLabel.numberOfLines = secondaryInstruction == nil ? 2 : 1
        
        if secondaryInstruction == nil {
            centerYAlignInstructions()
        } else {
            baselineAlignInstructions()
        }
        
        primaryLabel.instruction = instruction?.primaryInstruction
        maneuverView.visualInstruction = instruction?.primaryInstruction
        maneuverView.drivingSide = instruction?.drivingSide ?? .right
        secondaryLabel.instruction = secondaryInstruction
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        maneuverView.isStart = true
        let component = VisualInstructionComponent(type: .text, text: "Primary text label", imageURL: nil, abbreviation: nil, abbreviationPriority: NSNotFound)
        let instruction = VisualInstruction(text: nil, maneuverType: .none, maneuverDirection: .none, components: [component])
        primaryLabel.instruction = instruction
        
        distance = 100
    }
    
    /**
     Updates the instructions banner distance info for a given `RouteStepProgress`.
     */
    public func updateDistance(for currentStepProgress: RouteStepProgress) {
        let distanceRemaining = currentStepProgress.distanceRemaining
        distance = distanceRemaining > 5 ? distanceRemaining : 0
    }
}
