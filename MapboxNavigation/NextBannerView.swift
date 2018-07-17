import UIKit
import MapboxDirections
import MapboxCoreNavigation

/// :nodoc:
@objc(MBNextInstructionLabel)
open class NextInstructionLabel: InstructionLabel { }

/// :nodoc:
@IBDesignable
@objc(MBNextBannerView)
open class NextBannerView: UIView {
    
    weak var maneuverView: ManeuverView!
    weak var instructionLabel: NextInstructionLabel!
    weak var bottomSeparatorView: SeparatorView!
    weak var instructionDelegate: VisualInstructionDelegate? {
        didSet {
            instructionLabel.instructionDelegate = instructionDelegate
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
    }
    
    func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        
        let maneuverView = ManeuverView()
        maneuverView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(maneuverView)
        self.maneuverView = maneuverView
        
        let instructionLabel = NextInstructionLabel()
        instructionLabel.instructionDelegate = instructionDelegate
        instructionLabel.shieldHeight = instructionLabel.font.pointSize
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(instructionLabel)
        self.instructionLabel = instructionLabel
        
        instructionLabel.availableBounds = { [unowned self] in
            // Available width H:|-padding-maneuverView-padding-availableWidth-padding-|
            let availableWidth = self.bounds.width - BaseInstructionsBannerView.maneuverViewSize.width - BaseInstructionsBannerView.padding * 3
            return CGRect(x: 0, y: 0, width: availableWidth, height: self.instructionLabel.font.lineHeight)
        }
        
        let bottomSeparatorView = SeparatorView()
        bottomSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomSeparatorView)
        self.bottomSeparatorView = bottomSeparatorView
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        maneuverView.isEnd = true
        let component = VisualInstructionComponent(type: .text, text: "Next step", imageURL: nil, abbreviation: nil, abbreviationPriority: NSNotFound)
        let instruction = VisualInstruction(text: nil, maneuverType: .none, maneuverDirection: .none, components: [component])
        instructionLabel.instruction = instruction
    }
    
    func setupLayout() {
        let heightConstraint = heightAnchor.constraint(equalToConstant: 44)
        heightConstraint.priority = UILayoutPriority(rawValue: 999)
        heightConstraint.isActive = true
        
        let midX = BaseInstructionsBannerView.padding + BaseInstructionsBannerView.maneuverViewSize.width / 2
        maneuverView.centerXAnchor.constraint(equalTo: leadingAnchor, constant: midX).isActive = true
        maneuverView.heightAnchor.constraint(equalToConstant: 22).isActive = true
        maneuverView.widthAnchor.constraint(equalToConstant: 22).isActive = true
        maneuverView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        instructionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 70).isActive = true
        instructionLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        instructionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        
        bottomSeparatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        bottomSeparatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        bottomSeparatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        bottomSeparatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
    }
    
    /**
     Updates the instructions banner info with a given `VisualInstructionBanner`.
     */
    @objc(updateForVisualInstructionBanner:)
    public func update(for visualInstruction: VisualInstructionBanner?) {
        guard let tertiaryInstruction = visualInstruction?.tertiaryInstruction, !tertiaryInstruction.containsLaneIndications else {
            hide()
            return
        }
        
        maneuverView.visualInstruction = tertiaryInstruction
        maneuverView.drivingSide = visualInstruction?.drivingSide ?? .right
        instructionLabel.instruction = tertiaryInstruction
        show()
    }
    
    public func show() {
        guard isHidden else { return }
        UIView.defaultAnimation(0.3, animations: {
            self.isHidden = false
        }, completion: nil)
    }
    
    public func hide() {
        guard !isHidden else { return }
        UIView.defaultAnimation(0.3, animations: {
            self.isHidden = true
        }, completion: nil)
    }
    
}
