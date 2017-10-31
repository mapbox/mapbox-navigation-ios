import UIKit
import MapboxCoreNavigation

@IBDesignable
@objc(MBInstructionsBannerView)
open class InstructionsBannerView: UIView {
    
    weak var maneuverView: ManeuverView!
    weak var primaryLabel: PrimaryLabel!
    weak var secondaryLabel: SecondaryLabel!
    weak var distanceLabel: DistanceLabel!
    weak var dividerView: UIView!
    weak var separatorView: UIView!
    
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
    
    func set(_ primaryInstruction: Instruction?, secondaryInstruction: Instruction?) {
        primaryLabel.instruction = primaryInstruction
        secondaryLabel.instruction = secondaryInstruction
        
        if secondaryInstruction == nil {
            centerYAlignInstructions()
        } else {
            baselineAlignInstructions()
        }
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        maneuverView.isStart = true
        primaryLabel.text = "Primary Label"
        secondaryLabel.text = "Secondary Label"
        distanceLabel.text = "100m"
    }
}
