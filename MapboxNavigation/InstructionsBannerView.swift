import UIKit

@IBDesignable
@objc(MBInstructionsBannerView)
class InstructionsBannerView: UIView {
    
    weak var turnArrowView: TurnArrowView!
    weak var primaryLabel: PrimaryLabel!
    weak var secondaryLabel: SecondaryLabel!
    weak var distanceLabel: DistanceLabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func set(primary: String?, secondary: String?) {
        primaryLabel.text = primary
        secondaryLabel.text = secondary
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        turnArrowView.isStart = true
        primaryLabel.text = "Primary Label"
        secondaryLabel.text = "Secondary Label"
        distanceLabel.text = "100m"
    }
}
