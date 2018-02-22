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
    weak var secondaryLabel: SecondaryLabel!
    weak var distanceLabel: DistanceLabel!
    weak var dividerView: UIView!
    weak var _separatorView: UIView!
    weak var separatorView: SeparatorView!
    weak var delegate: InstructionsBannerViewDelegate?
    
    var centerYConstraints = [NSLayoutConstraint]()
    var baselineConstraints = [NSLayoutConstraint]()
    
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
        setupLayout()
        centerYAlignInstructions()
        setupAvailableBounds()
    }
    
    @IBAction func tappedInstructionsBanner(_ sender: Any) {
        delegate?.didTapInstructionsBanner(self)
    }
    
    func set(_ instruction: VisualInstruction?) {
        let secondaryInstruction = instruction?.secondaryTextComponents
        primaryLabel.numberOfLines = secondaryInstruction == nil ? 2 : 1
        
        if secondaryInstruction == nil {
            centerYAlignInstructions()
        } else {
            baselineAlignInstructions()
        }
        
        primaryLabel.instruction = instruction?.primaryTextComponents
        secondaryLabel.instruction = secondaryInstruction
        maneuverView.visualInstruction = instruction
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        maneuverView.isStart = true
        
        primaryLabel.instruction = [VisualInstructionComponent(type: .destination, text: "Primary text label", imageURL: nil, maneuverType: .none, maneuverDirection: .none)]
        
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
            if stepProgress.distanceRemaining <= visualInstruction.distanceAlongStep {
                
                set(visualInstruction)
                
                stepProgress.visualInstructionIndex += 1
                break
            }
        }
        
        distance = distanceRemaining > 5 ? distanceRemaining : 0
    }
}
