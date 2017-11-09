import UIKit

/// :nodoc:
@objc(MBNextInstructionLabel)
class NextInstructionLabel: InstructionLabel { }

/// :nodoc:
@IBDesignable
@objc(MBNextBannerView)
class NextBannerView: UIView {
    
    weak var maneuverView: ManeuverView!
    weak var instructionLabel: NextInstructionLabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        setupViews()
        setupLayout()
    }
    
    func setupViews() {
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
            let height = ("|" as NSString).size(attributes: [NSFontAttributeName: self.instructionLabel.font]).height
            let availableWidth = self.bounds.width-self.maneuverView.frame.maxX-(16*2)
            return CGRect(x: 0, y: 0, width: availableWidth, height: height)
        }
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        maneuverView.isEnd = true
        instructionLabel.text = "San Jose"
    }
    
    func setupLayout() {
        heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        maneuverView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16).isActive = true
        maneuverView.heightAnchor.constraint(equalToConstant: 22).isActive = true
        maneuverView.widthAnchor.constraint(equalToConstant: 22).isActive = true
        maneuverView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        instructionLabel.leftAnchor.constraint(equalTo: maneuverView.rightAnchor, constant: 16).isActive = true
        instructionLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        instructionLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16).isActive = true
    }
    
}
