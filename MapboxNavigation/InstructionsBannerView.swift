import UIKit
import MapboxCoreNavigation

@IBDesignable
@objc(MBInstructionsBannerView)
class InstructionsBannerView: UIView {
    
    weak var turnArrowView: TurnArrowView!
    weak var primaryLabel: PrimaryLabel!
    weak var secondaryLabel: SecondaryLabel!
    weak var distanceLabel: DistanceLabel!
    weak var stackView: UIStackView!
    
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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func set(primary: String?, secondary: String?) {
        primaryLabel.unabridgedText = primary
        secondaryLabel.unabridgedText = secondary
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        turnArrowView.isStart = true
        primaryLabel.text = "Primary Label"
        secondaryLabel.text = "Secondary Label"
        distanceLabel.text = "100m"
    }
}
