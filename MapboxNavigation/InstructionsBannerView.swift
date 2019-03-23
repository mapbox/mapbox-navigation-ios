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
    @available(*, deprecated, message: "Please use didSwipeInstructionsBanner instead.")
    @objc(didDragInstructionsBanner:)
    optional func didDragInstructionsBanner(_ sender: BaseInstructionsBannerView)
    
    /**
     Called when the user swipes either left, right, or down on the `InstructionsBannerView`
     */
    @objc optional func didSwipeInstructionsBanner(_ sender: BaseInstructionsBannerView, swipeDirection direction: UISwipeGestureRecognizer.Direction)
}

@objc private protocol InstructionsBannerViewDelegateDeprecations {
    @objc(didDragInstructionsBanner:)
    optional func didDragInstructionsBanner(_ sender: BaseInstructionsBannerView)
}

/// :nodoc:
@IBDesignable
@objc(MBInstructionsBannerView)
open class InstructionsBannerView: BaseInstructionsBannerView, NavigationComponent {
    @objc public func navigationService(_ service: NavigationService, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress) {
        update(for: instruction)
    }
}

/// :nodoc:
open class BaseInstructionsBannerView: UIControl {
    
    public weak var maneuverView: ManeuverView!
    public weak var primaryLabel: PrimaryLabel!
    public weak var secondaryLabel: SecondaryLabel!
    public weak var distanceLabel: DistanceLabel!
    public weak var dividerView: UIView!
    weak var _separatorView: UIView!
    public weak var separatorView: SeparatorView!
    public weak var stepListIndicatorView: StepListIndicatorView!
    
    @IBInspectable
    public var swipeable: Bool = false
    
    @IBInspectable
    public var showStepIndicator: Bool = true {
        didSet {
            stepListIndicatorView.isHidden = !showStepIndicator
        }
    }
    
    public weak var delegate: InstructionsBannerViewDelegate? {
        didSet {
            if showStepIndicator {
               stepListIndicatorView.isHidden = false
            }
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
    
    public var distance: CLLocationDistance? {
        didSet {
            distanceLabel.attributedDistanceString = nil
            
            if let distance = distance {
                distanceLabel.attributedDistanceString = distanceFormatter.attributedString(for: distance)
            } else {
                distanceLabel.text = nil
            }
        }
    }
    
    public override init(frame: CGRect) {
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
        stepListIndicatorView.isHidden = !showStepIndicator
    }
    
    @objc func swipedInstructionBannerLeft(_ sender: Any) {
        if !swipeable {
            return
        }

        if let gestureRecognizer = sender as? UISwipeGestureRecognizer, gestureRecognizer.state == .ended {
            if let delegate = delegate {
                delegate.didSwipeInstructionsBanner?(self, swipeDirection: .left)
            }
        }
    }
    
    @objc func swipedInstructionBannerRight(_ sender: Any) {
        if !swipeable {
            return
        }
        
        if let gestureRecognizer = sender as? UISwipeGestureRecognizer, gestureRecognizer.state == .ended {
            if let delegate = delegate {
                delegate.didSwipeInstructionsBanner?(self, swipeDirection: .right)
            }
        }
    }
    
    @objc func swipedInstructionBannerDown(_ sender: Any) {
        if let gestureRecognizer = sender as? UISwipeGestureRecognizer, gestureRecognizer.state == .ended {
            if showStepIndicator {
               stepListIndicatorView.isHidden = !stepListIndicatorView.isHidden
            }
            
            if let delegate = delegate {
                delegate.didSwipeInstructionsBanner?(self, swipeDirection: .down)
                (delegate as? InstructionsBannerViewDelegateDeprecations)?.didDragInstructionsBanner?(self)
            }
        }
    }
        
    @objc func tappedInstructionsBanner(_ sender: Any) {
        if let delegate = delegate {
            if showStepIndicator {
                stepListIndicatorView.isHidden = !stepListIndicatorView.isHidden
            }
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
