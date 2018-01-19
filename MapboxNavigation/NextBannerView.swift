import UIKit
import MapboxDirections

/// :nodoc:
@objc(MBNextInstructionLabel)
open class NextInstructionLabel: InstructionLabel { }

/// :nodoc:
@IBDesignable
@objc(MBNextBannerView)
open class NextBannerView: UIView {
    
    weak var maneuverView: ManeuverView!
    weak var instructionLabel: NextInstructionLabel!
    
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
    }
    
    func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        
        let maneuverView = ManeuverView()
        maneuverView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(maneuverView)
        self.maneuverView = maneuverView
        
        let instructionLabel = NextInstructionLabel()
        instructionLabel.shieldHeight = instructionLabel.font.pointSize
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(instructionLabel)
        self.instructionLabel = instructionLabel
        
        instructionLabel.availableBounds = {
            let height = ("|" as NSString).size(withAttributes: [.font: self.instructionLabel.font]).height
            let availableWidth = self.bounds.width-self.maneuverView.frame.maxX-(16*2)
            return CGRect(x: 0, y: 0, width: availableWidth, height: height)
        }
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        maneuverView.isEnd = true
        instructionLabel.instruction = [VisualInstructionComponent(type: .destination, text: "Next step", imageURL: nil)]
    }
    
    func setupLayout() {
        let heightConstraint = heightAnchor.constraint(equalToConstant: 44)
        heightConstraint.priority = UILayoutPriority(rawValue: 999)
        heightConstraint.isActive = true
        
        let midX = BaseInstructionsBannerView.padding + BaseInstructionsBannerView.maneuverViewSize.width / 2
        maneuverView.centerXAnchor.constraint(equalTo: leftAnchor, constant: midX).isActive = true
        maneuverView.heightAnchor.constraint(equalToConstant: 22).isActive = true
        maneuverView.widthAnchor.constraint(equalToConstant: 22).isActive = true
        maneuverView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        instructionLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 70).isActive = true
        instructionLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        instructionLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16).isActive = true
    }
    
}
