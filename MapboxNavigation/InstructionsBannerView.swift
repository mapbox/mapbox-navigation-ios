import UIKit
import MapboxCoreNavigation
import MapboxDirections

@objc(MBInstructionsBannerViewDelegate)
protocol InstructionsBannerViewDelegate: class {
    
    @objc(didTapInstructionsBanner:)
    optional func didTapInstructionsBanner(_ sender: BaseInstructionsBannerView)
    
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
    weak var delegate: InstructionsBannerViewDelegate? {
        didSet {
            stepListIndicatorView.isHidden = false
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
    
    func set(_ instruction: VisualInstructionBanner?) {
        let secondaryInstruction = instruction?.secondaryInstruction
        primaryLabel.numberOfLines = secondaryInstruction == nil ? 2 : 1
        
        if secondaryInstruction == nil {
            centerYAlignInstructions()
        } else {
            baselineAlignInstructions()
        }
        
        primaryLabel.instruction = instruction?.primaryInstruction
        secondaryLabel.instruction = secondaryInstruction
        maneuverView.visualInstruction = instruction
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        maneuverView.isStart = true
        let component = VisualInstructionComponent(type: .text, text: "Primary text label", imageURL: nil, abbreviation: nil, abbreviationPriority: NSNotFound)
        let instruction = VisualInstruction(text: nil, maneuverType: .none, maneuverDirection: .none, textComponents: [component])
        primaryLabel.instruction = instruction
        
        distance = 100
    }
    
    /**
     Updates the instructions banner for a given `RouteProgress`.
     */
    public func update(for currentLegProgress: RouteLegProgress) {
        let stepProgress = currentLegProgress.currentStepProgress
        let distanceRemaining = stepProgress.distanceRemaining
        
        guard let visualInstructions = stepProgress.remainingVisualInstructions else { return }
        
        for visualInstruction in visualInstructions {
            if stepProgress.distanceRemaining <= visualInstruction.distanceAlongStep || stepProgress.visualInstructionIndex == 0 {
                
                set(visualInstruction)
                
                stepProgress.visualInstructionIndex += 1
                break
            }
        }
        
        distance = distanceRemaining > 5 ? distanceRemaining : 0
    }
}
